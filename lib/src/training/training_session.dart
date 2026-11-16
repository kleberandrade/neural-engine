import 'dart:math' as math;
import 'async/async_training_result.dart';
import 'async/training_cancellation.dart';
import 'async/training_progress.dart';
import '../contracts/differentiable_model.dart';
import '../contracts/json_model.dart';
import '../losses/loss.dart';
import '../optimizers/checkpoint_optimizer.dart';
import '../persistence/training_checkpoint.dart';
import '../persistence/optimizer_codec.dart';
import 'mini_batch_trainer.dart';
import 'training_history.dart';

/// Retains optimizer state across fixed-epoch fits, using absolute-epoch shuffles.
/// Restore with the same data order, loss, batch size and clipping for exact replay.
/// Built-in early stopping is intentionally handled by ordinary model.fit instead.
class TrainingSession<I> {
  final DifferentiableModel<I> model;
  final CheckpointOptimizer optimizer;
  final int seed;
  late final CheckpointOptimizerState _state;
  int _epochsCompleted = 0;
  int get epochsCompleted => _epochsCompleted;
  bool _failed = false;
  bool _busy = false;
  TrainingSession({required this.model, required this.optimizer, int? seed})
      : seed = seed ?? math.Random().nextInt(0x7fffffff) {
    if (this.seed < 0 || this.seed > 0x7fffffff) {
      throw ArgumentError(
          'Session seed must fit a nonnegative 31-bit integer.');
    }
    final state = optimizer.createState(model.parameterCount);
    if (state is! CheckpointOptimizerState) {
      throw ArgumentError('Optimizer state must support checkpoints.');
    }
    _state = state;
  }
  TrainingSession._(this.model, this.optimizer, this.seed,
      this._epochsCompleted, TrainingCheckpoint checkpoint) {
    _state =
        optimizer.restoreState(checkpoint.optimizerState, model.parameterCount);
  }
  factory TrainingSession.restore(
      {required TrainingCheckpoint checkpoint,
      required DifferentiableModel<I> Function(Map<String, dynamic>)
          modelDecoder,
      CheckpointOptimizer Function(Map<String, dynamic>)? optimizerDecoder}) {
    final model = modelDecoder(checkpoint.model);
    final optimizer =
        (optimizerDecoder ?? OptimizerCodec.decode)(checkpoint.optimizer);
    return TrainingSession._(model, optimizer, checkpoint.seed,
        checkpoint.epochsCompleted, checkpoint);
  }
  TrainingHistory fit(
      {required List<I> inputs,
      required List<List<double>> targets,
      required Loss loss,
      int epochs = 1,
      int batchSize = 32,
      bool shuffle = true,
      double? maxGradientNorm}) {
    if (_busy) throw StateError('Session is already training asynchronously.');
    if (_failed) {
      throw StateError(
          'Session failed; restore a previous checkpoint before continuing.');
    }
    try {
      final result = MiniBatchTrainer<I>().fit(
          model: model,
          optimizer: optimizer,
          optimizerState: _state,
          seed: seed,
          epochOffset: _epochsCompleted,
          epochSeededShuffle: true,
          inputs: inputs,
          targets: targets,
          loss: loss,
          epochs: epochs,
          batchSize: batchSize,
          shuffle: shuffle,
          maxGradientNorm: maxGradientNorm);
      _epochsCompleted += result.epochs;
      return result;
    } on Object {
      _failed = true;
      rethrow;
    }
  }

  /// Trains with the same batch executor as [fit], yielding to the event loop
  /// after [batchesPerYield] batches. Cancellation commits the current epoch.
  /// Custom models/losses/optimizers are supported in this cooperative mode.
  /// Do not mutate caller-owned model or dataset while this future is active.
  Future<AsyncTrainingResult> fitAsync({
    required List<I> inputs,
    required List<List<double>> targets,
    required Loss loss,
    int epochs = 1,
    int batchSize = 32,
    bool shuffle = true,
    double? maxGradientNorm,
    List<I>? validationInputs,
    List<List<double>>? validationTargets,
    int batchesPerYield = 1,
    TrainingCancellation? cancellation,
    void Function(TrainingProgress)? onProgress,
  }) async {
    if (_busy || _failed) throw StateError('Session is busy or failed.');
    if (epochs <= 0 ||
        batchSize <= 0 ||
        batchesPerYield <= 0 ||
        (validationInputs == null) != (validationTargets == null) ||
        (maxGradientNorm != null &&
            (!maxGradientNorm.isFinite || maxGradientNorm <= 0))) {
      throw ArgumentError('Invalid asynchronous training configuration.');
    }
    _busy = true;
    final clock = Stopwatch()..start();
    final losses = <double>[];
    final validationLosses = <double>[];
    try {
      // Validate even a pre-cancelled job, without changing any weights.
      final initial =
          model.evaluate(inputs: inputs, targets: targets, loss: loss);
      if (!initial.isFinite) throw StateError('Nonfinite training loss.');
      if (validationInputs != null) {
        final value = model.evaluate(
            inputs: validationInputs, targets: validationTargets!, loss: loss);
        if (!value.isFinite) throw StateError('Nonfinite validation loss.');
      }
      // A zero-duration timer yields to browser/UI events, not just microtasks.
      await Future<void>.delayed(Duration.zero);
      for (var epoch = 0; epoch < epochs; epoch++) {
        if (cancellation?.isCancelled ?? false) break;
        TrainingHistory? history;
        var batches = 0;
        for (final step in MiniBatchTrainer<I>().steps(
          model: model,
          optimizer: optimizer,
          optimizerState: _state,
          seed: seed,
          epochOffset: _epochsCompleted,
          epochSeededShuffle: true,
          inputs: inputs,
          targets: targets,
          loss: loss,
          epochs: 1,
          batchSize: batchSize,
          shuffle: shuffle,
          maxGradientNorm: maxGradientNorm,
          validationInputs: validationInputs,
          validationTargets: validationTargets,
        )) {
          if (step != null) {
            history = step;
          } else if (++batches % batchesPerYield == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }
        _epochsCompleted++;
        losses.add(history!.losses.single);
        validationLosses.addAll(history.validationLosses);
        onProgress?.call(TrainingProgress(
          epochsCompleted: _epochsCompleted,
          requestedEpochs: epochs,
          epochsThisRun: losses.length,
          loss: losses.last,
          validationLoss:
              validationLosses.isEmpty ? null : validationLosses.last,
          elapsed: clock.elapsed,
        ));
        await Future<void>.delayed(Duration.zero);
      }
      clock.stop();
      // All iterators have completed: the checkpoint is at an epoch boundary.
      return AsyncTrainingResult(
          checkpoint: _checkpoint(),
          history: TrainingHistory(losses, validationLosses,
              stoppedEarly: false, bestEpoch: null),
          cancelled:
              losses.length < epochs && (cancellation?.isCancelled ?? false),
          elapsed: clock.elapsed);
    } on Object {
      _failed = true;
      rethrow;
    } finally {
      _busy = false;
      clock.stop();
    }
  }

  TrainingCheckpoint checkpoint() {
    if (_busy) throw StateError('Session is already training asynchronously.');
    if (_failed) {
      throw StateError(
          'Cannot checkpoint a failed session. Restore the last valid checkpoint.');
    }
    return _checkpoint();
  }

  TrainingCheckpoint _checkpoint() {
    final serializable = model;
    if (serializable is! JsonModel) {
      throw UnsupportedError(
          'Model must implement JsonModel to be checkpointed.');
    }
    return TrainingCheckpoint(
        model: (serializable as JsonModel).toJson(),
        optimizer: optimizer.toJson(),
        optimizerState: _state.toJson(),
        epochsCompleted: _epochsCompleted,
        seed: seed);
  }
}

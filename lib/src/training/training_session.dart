import 'dart:math' as math;
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

  TrainingCheckpoint checkpoint() {
    if (_failed) {
      throw StateError(
          'Cannot checkpoint a failed session. Restore the last valid checkpoint.');
    }
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

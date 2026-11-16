import 'dart:math' as math;
import '../contracts/differentiable_model.dart';
import '../losses/loss.dart';
import '../optimizers/optimizer.dart';
import 'training_history.dart';

/// Shared supervised training lifecycle; model math stays in model executors.
class MiniBatchTrainer<I> {
  TrainingHistory fit({
    required DifferentiableModel<I> model,
    int? seed,
    OptimizerState? optimizerState,
    int epochOffset = 0,
    bool epochSeededShuffle = false,
    double? maxGradientNorm,
    required List<I> inputs,
    required List<List<double>> targets,
    required Loss loss,
    required Optimizer optimizer,
    int epochs = 1000,
    int batchSize = 32,
    bool shuffle = true,
    List<I>? validationInputs,
    List<List<double>>? validationTargets,
    int? patience,
    double minDelta = 0,
  }) {
    return steps(
      model: model,
      seed: seed,
      optimizerState: optimizerState,
      epochOffset: epochOffset,
      epochSeededShuffle: epochSeededShuffle,
      maxGradientNorm: maxGradientNorm,
      inputs: inputs,
      targets: targets,
      loss: loss,
      optimizer: optimizer,
      epochs: epochs,
      batchSize: batchSize,
      shuffle: shuffle,
      validationInputs: validationInputs,
      validationTargets: validationTargets,
      patience: patience,
      minDelta: minDelta,
    ).last!;
  }

  /// Shared incremental executor. Null marks a completed mini-batch; the final
  /// value is the history. Exhaust this iterator to commit the entire fit.
  /// Used by TrainingSession's cooperative runner; abandoning it mid-epoch
  /// leaves partial updates and must not be represented as a checkpoint.
  Iterable<TrainingHistory?> steps({
    required DifferentiableModel<I> model,
    int? seed,
    OptimizerState? optimizerState,
    int epochOffset = 0,
    bool epochSeededShuffle = false,
    double? maxGradientNorm,
    required List<I> inputs,
    required List<List<double>> targets,
    required Loss loss,
    required Optimizer optimizer,
    int epochs = 1000,
    int batchSize = 32,
    bool shuffle = true,
    List<I>? validationInputs,
    List<List<double>>? validationTargets,
    int? patience,
    double minDelta = 0,
  }) sync* {
    if (epochOffset < 0 ||
        (epochSeededShuffle && seed == null) ||
        (maxGradientNorm != null &&
            (!maxGradientNorm.isFinite || maxGradientNorm <= 0)) ||
        epochs <= 0 ||
        batchSize <= 0 ||
        !minDelta.isFinite ||
        minDelta < 0 ||
        (patience != null && patience <= 0) ||
        (validationInputs == null) != (validationTargets == null) ||
        (patience != null && validationInputs == null)) {
      throw ArgumentError('Invalid training or validation configuration.');
    }
    // Validate complete datasets before any weight updates.
    _finiteLoss(model.evaluate(inputs: inputs, targets: targets, loss: loss));
    if (validationInputs != null) {
      _finiteLoss(model.evaluate(
        inputs: validationInputs,
        targets: validationTargets!,
        loss: loss,
      ));
    }
    final state = optimizerState ?? optimizer.createState(model.parameterCount);
    final random = math.Random(seed);
    final order = List.generate(inputs.length, (i) => i);
    final losses = <double>[];
    final validationLosses = <double>[];
    var best = double.infinity;
    List<double>? bestParameters;
    int? bestEpoch;
    var stale = 0;
    var stopped = false;
    for (var epoch = 0; epoch < epochs; epoch++) {
      if (epochSeededShuffle) {
        for (var i = 0; i < order.length; i++) {
          order[i] = i;
        }
        if (shuffle) {
          order.shuffle(math.Random(
              (seed! + (epochOffset + epoch) * 0x9e3779b9) & 0x7fffffff));
        }
      } else if (shuffle) {
        order.shuffle(random);
      }
      for (var start = 0; start < order.length; start += batchSize) {
        final end = math.min(start + batchSize, order.length);
        final average = List<double>.filled(model.parameterCount, 0);
        for (var n = start; n < end; n++) {
          final i = order[n];
          final g =
              model.gradients(input: inputs[i], target: targets[i], loss: loss);
          if (g.length != model.parameterCount) {
            throw StateError('Gradient dimension mismatch.');
          }
          for (var p = 0; p < model.parameterCount; p++) {
            average[p] += g[p] / (end - start);
          }
        }
        if (average.any((v) => !v.isFinite)) {
          throw StateError('Nonfinite batch gradient.');
        }
        if (maxGradientNorm != null) {
          var scale = 0.0;
          for (final g in average) {
            scale = math.max(scale, g.abs());
          }
          if (scale > 0) {
            final unitNorm = math.sqrt(average.fold<double>(
                0, (s, g) => s + (g / scale) * (g / scale)));
            final factor = (maxGradientNorm / scale) / unitNorm;
            if (factor < 1) {
              for (var p = 0; p < average.length; p++) {
                average[p] *= factor;
              }
            }
          }
        }
        // Candidate updates make optimizer overflow failures atomic per batch.
        final candidate = List<double>.of(model.parameters);
        state.update(candidate, average);
        if (candidate.length != model.parameterCount ||
            candidate.any((x) => !x.isFinite)) {
          throw StateError(
            'Optimizer produced nonfinite weights; lower the learning rate.',
          );
        }
        model.parameters = candidate;
        yield null;
      }
      losses.add(_finiteLoss(
          model.evaluate(inputs: inputs, targets: targets, loss: loss)));
      if (validationInputs != null) {
        final value = _finiteLoss(model.evaluate(
          inputs: validationInputs,
          targets: validationTargets!,
          loss: loss,
        ));
        validationLosses.add(value);
        if (value < best - minDelta) {
          best = value;
          bestParameters = List.of(model.parameters);
          bestEpoch = epoch + 1;
          stale = 0;
        } else {
          stale++;
        }
        if (patience != null && stale >= patience) {
          stopped = true;
          break;
        }
      }
    }
    if (patience != null && bestParameters != null) {
      model.parameters = bestParameters;
    }
    yield TrainingHistory(
      losses,
      validationLosses,
      stoppedEarly: stopped,
      bestEpoch: bestEpoch,
    );
  }
}

double _finiteLoss(double value) {
  if (!value.isFinite) {
    throw StateError('Model evaluation must return a finite loss.');
  }
  return value;
}

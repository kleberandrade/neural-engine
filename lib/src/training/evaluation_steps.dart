import '../contracts/differentiable_model.dart';
import '../contracts/sample_loss_model.dart';
import '../losses/loss.dart';
import 'training_step.dart';

/// Preserves sample order and a single final division, never averages averages.
Iterable<TrainingStep> evaluationSteps<I>(
    {required DifferentiableModel<I> model,
    required List<I> inputs,
    required List<List<double>> targets,
    required Loss loss,
    required TrainingPhase phase,
    required int epoch,
    required int chunkSize}) sync* {
  if (inputs.isEmpty || inputs.length != targets.length || chunkSize <= 0) {
    throw ArgumentError(
        'Expected matching nonempty evaluation data and positive chunk size.');
  }
  if (model is! SampleLossModel<I>) {
    final value = model.evaluate(inputs: inputs, targets: targets, loss: loss);
    if (!value.isFinite) throw StateError('Nonfinite evaluation loss.');
    yield TrainingStep(phase,
        epoch: epoch,
        samplesCompleted: inputs.length,
        totalSamples: inputs.length,
        loss: value,
        incremental: false);
    return;
  }
  final incremental = model as SampleLossModel<I>;
  var total = 0.0;
  for (var i = 0; i < inputs.length; i++) {
    final value = incremental.sampleLoss(
        input: inputs[i], target: targets[i], loss: loss);
    if (!value.isFinite) throw StateError('Nonfinite sample loss.');
    total += value;
    if ((i + 1) % chunkSize == 0 || i + 1 == inputs.length) {
      final mean = i + 1 == inputs.length ? total / inputs.length : null;
      if (mean != null && !mean.isFinite) {
        throw StateError('Nonfinite evaluation loss.');
      }
      yield TrainingStep(phase,
          epoch: epoch,
          samplesCompleted: i + 1,
          totalSamples: inputs.length,
          loss: mean);
    }
  }
}

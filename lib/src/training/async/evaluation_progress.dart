import '../training_step.dart';

/// Evaluation progress is separate from committed-epoch TrainingProgress.
/// Partial chunks do not report an averaged loss; only a complete dataset does.
class EvaluationProgress {
  final TrainingPhase phase;
  final int epoch, samplesCompleted, totalSamples;
  final double? loss;
  final bool incremental;
  const EvaluationProgress(
      {required this.phase,
      required this.epoch,
      required this.samplesCompleted,
      required this.totalSamples,
      required this.loss,
      required this.incremental});
}

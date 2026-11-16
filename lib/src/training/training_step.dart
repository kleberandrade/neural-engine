import 'training_history.dart';

/// Explicit safe scheduling units of the common numerical executor.
enum TrainingPhase {
  trainingPreflight,
  validationPreflight,
  batchUpdate,
  trainingEvaluation,
  validationEvaluation,
  epochComplete,
  completed
}

class TrainingStep {
  final TrainingPhase phase;
  final int epoch;
  final int samplesCompleted, totalSamples;
  final double? loss, validationLoss;
  final bool incremental;
  final TrainingHistory? history;
  const TrainingStep(this.phase,
      {required this.epoch,
      this.samplesCompleted = 0,
      this.totalSamples = 0,
      this.loss,
      this.validationLoss,
      this.incremental = true,
      this.history});
  bool get isEvaluation =>
      phase == TrainingPhase.trainingPreflight ||
      phase == TrainingPhase.validationPreflight ||
      phase == TrainingPhase.trainingEvaluation ||
      phase == TrainingPhase.validationEvaluation;
}

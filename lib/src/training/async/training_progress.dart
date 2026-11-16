/// Measurements after a complete epoch. Epoch counts are absolute (resume-safe).
class TrainingProgress {
  final int epochsCompleted;
  final int requestedEpochs;
  final int epochsThisRun;
  final double loss;
  final double? validationLoss;
  final Duration elapsed;
  const TrainingProgress(
      {required this.epochsCompleted,
      required this.requestedEpochs,
      required this.epochsThisRun,
      required this.loss,
      required this.validationLoss,
      required this.elapsed});
  double get fraction => epochsThisRun / requestedEpochs;
}

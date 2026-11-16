/// Immutable losses measured after each completed epoch.
class TrainingHistory {
  final List<double> losses;
  final List<double> validationLosses;
  final bool stoppedEarly;
  final int? bestEpoch;
  int get epochs => losses.length;
  TrainingHistory(
    List<double> losses,
    List<double> validationLosses, {
    required this.stoppedEarly,
    required this.bestEpoch,
  })  : losses = List.unmodifiable(losses),
        validationLosses = List.unmodifiable(validationLosses);
}

/// Confusion rows are targets, columns predictions. Undefined ratios are zero.
class ClassificationMetrics {
  final List<List<int>> confusionMatrix;
  ClassificationMetrics._(List<List<int>> counts)
      : confusionMatrix =
            List.unmodifiable(counts.map((r) => List<int>.unmodifiable(r)));
  factory ClassificationMetrics.fromLabels(
      {required List<int> targets,
      required List<int> predictions,
      required int classCount}) {
    if (targets.isEmpty ||
        targets.length != predictions.length ||
        classCount <= 0 ||
        [...targets, ...predictions].any((v) => v < 0 || v >= classCount)) {
      throw ArgumentError('Invalid class labels.');
    }
    final counts =
        List.generate(classCount, (_) => List<int>.filled(classCount, 0));
    for (var i = 0; i < targets.length; i++) {
      counts[targets[i]][predictions[i]]++;
    }
    return ClassificationMetrics._(counts);
  }
  int get _count => confusionMatrix.expand((r) => r).reduce((a, b) => a + b);
  double get accuracy =>
      List.generate(confusionMatrix.length, (i) => confusionMatrix[i][i])
          .reduce((a, b) => a + b) /
      _count;
  List<double> get precision => List.generate(
      confusionMatrix.length,
      (i) => _ratio(confusionMatrix[i][i],
          confusionMatrix.fold<int>(0, (s, row) => s + row[i])));
  List<double> get recall => List.generate(
      confusionMatrix.length,
      (i) => _ratio(
          confusionMatrix[i][i], confusionMatrix[i].reduce((a, b) => a + b)));
  List<double> get f1 => List.generate(
      confusionMatrix.length,
      (i) => precision[i] + recall[i] == 0
          ? 0.0
          : 2 * precision[i] * recall[i] / (precision[i] + recall[i]));
  double get macroF1 => f1.reduce((a, b) => a + b) / f1.length;
}

double _ratio(int n, int d) => d == 0 ? 0.0 : n / d;

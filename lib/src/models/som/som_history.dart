/// Immutable post-epoch average Euclidean quantization errors.
class SomHistory {
  final List<double> quantizationErrors;
  SomHistory(List<double> values)
      : quantizationErrors = List.unmodifiable(values);
}

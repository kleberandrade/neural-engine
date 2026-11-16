/// A fitted, immutable transform. Fit on training data only.
abstract interface class FeatureTransform {
  List<double> transform(List<double> input);
  List<double> inverseTransform(List<double> input);
}

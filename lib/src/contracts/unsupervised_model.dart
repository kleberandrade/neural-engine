/// Quality evaluation without labels; SOM uses mean BMU distance.
abstract interface class UnsupervisedModel<I> {
  double quantizationError(List<I> inputs);
}

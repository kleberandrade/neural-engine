/// Stateless inference boundary: each call returns an independent output.
abstract interface class Predictor<I> {
  List<double> predict(I input);
}

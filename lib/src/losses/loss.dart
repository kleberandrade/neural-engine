/// Loss extension point. Gradients are with respect to predicted outputs.
abstract interface class Loss {
  double value(List<double> predicted, List<double> target);
  List<double> gradient(List<double> predicted, List<double> target);
}

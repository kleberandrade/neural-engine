/// Flat, finite parameter snapshots; setters must copy and validate input.
abstract interface class ParameterizedModel {
  int get parameterCount;
  List<double> get parameters;
  set parameters(List<double> values);
}

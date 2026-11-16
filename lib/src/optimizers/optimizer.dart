/// An optimizer configuration creates isolated state for each fit invocation.
abstract interface class Optimizer {
  OptimizerState createState(int parameterCount);
}

/// Updates a flat parameter vector once per mini-batch.
abstract interface class OptimizerState {
  void update(List<double> parameters, List<double> gradients);
}

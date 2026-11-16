import 'optimizer.dart';
import 'optimizer_validation.dart';

/// Stochastic (or mini-batch) gradient descent without momentum.
class SGD implements Optimizer {
  final double learningRate;
  SGD({this.learningRate = 0.01}) {
    validateLearningRate(learningRate);
  }
  @override
  OptimizerState createState(int parameterCount) => _SgdState(learningRate);
}

class _SgdState implements OptimizerState {
  final double rate;
  _SgdState(this.rate);
  @override
  void update(List<double> parameters, List<double> gradients) {
    for (var i = 0; i < parameters.length; i++) {
      parameters[i] -= rate * gradients[i];
    }
  }
}

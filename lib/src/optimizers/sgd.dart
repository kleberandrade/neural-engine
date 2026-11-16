import 'optimizer.dart';
import 'checkpoint_optimizer.dart';
import '../persistence/json_validation.dart';
import 'optimizer_validation.dart';

/// Stochastic (or mini-batch) gradient descent without momentum.
class SGD implements CheckpointOptimizer {
  final double learningRate;
  SGD({this.learningRate = 0.01}) {
    validateLearningRate(learningRate);
  }
  factory SGD.fromJson(Map<String, dynamic> json) {
    requireFormat(json, 'neural_engine_sgd');
    try {
      return SGD(learningRate: (json['learningRate'] as num).toDouble());
    } on Object catch (error) {
      throw FormatException('Invalid SGD configuration: $error');
    }
  }
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_sgd',
        'version': 1,
        'learningRate': learningRate
      };
  @override
  CheckpointOptimizerState restoreState(
      Map<String, dynamic> json, int parameterCount) {
    requireFormat(json, 'neural_engine_sgd_state');
    if (json['parameterCount'] != parameterCount) {
      throw const FormatException('SGD state dimension mismatch.');
    }
    return _SgdState(learningRate, parameterCount);
  }

  @override
  OptimizerState createState(int parameterCount) =>
      _SgdState(learningRate, parameterCount);
}

class _SgdState implements CheckpointOptimizerState {
  final double rate;
  final int parameterCount;
  _SgdState(this.rate, this.parameterCount);
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_sgd_state',
        'version': 1,
        'parameterCount': parameterCount
      };
  @override
  void update(List<double> parameters, List<double> gradients) {
    if (parameters.length != parameterCount ||
        gradients.length != parameterCount ||
        [...parameters, ...gradients].any((x) => !x.isFinite)) {
      throw ArgumentError('Invalid SGD update dimensions/values.');
    }
    for (var i = 0; i < parameters.length; i++) {
      parameters[i] -= rate * gradients[i];
    }
  }
}

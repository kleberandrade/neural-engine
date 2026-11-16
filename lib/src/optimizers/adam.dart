import 'dart:math' as math;
import 'optimizer.dart';
import 'optimizer_validation.dart';

/// Adam with bias-corrected first and second moments.
class Adam implements Optimizer {
  final double learningRate;
  final double beta1;
  final double beta2;
  final double epsilon;
  Adam({
    this.learningRate = 0.001,
    this.beta1 = 0.9,
    this.beta2 = 0.999,
    this.epsilon = 1e-8,
  }) {
    validateLearningRate(learningRate);
    if (!beta1.isFinite ||
        !beta2.isFinite ||
        beta1 < 0 ||
        beta1 >= 1 ||
        beta2 < 0 ||
        beta2 >= 1 ||
        !epsilon.isFinite ||
        epsilon <= 0) {
      throw ArgumentError('Invalid Adam coefficients.');
    }
  }
  @override
  OptimizerState createState(int parameterCount) =>
      _AdamState(this, parameterCount);
}

class _AdamState implements OptimizerState {
  final Adam config;
  final List<double> m;
  final List<double> v;
  int step = 0;
  _AdamState(this.config, int n)
      : m = List.filled(n, 0),
        v = List.filled(n, 0);
  @override
  void update(List<double> parameters, List<double> gradients) {
    step++;
    for (var i = 0; i < parameters.length; i++) {
      final g = gradients[i];
      m[i] = config.beta1 * m[i] + (1 - config.beta1) * g;
      v[i] = config.beta2 * v[i] + (1 - config.beta2) * g * g;
      final mh = m[i] / (1 - math.pow(config.beta1, step));
      final vh = v[i] / (1 - math.pow(config.beta2, step));
      parameters[i] -=
          config.learningRate * mh / (math.sqrt(vh) + config.epsilon);
    }
  }
}

import 'dart:math' as math;
import 'optimizer.dart';
import 'checkpoint_optimizer.dart';
import '../persistence/json_validation.dart';
import 'optimizer_validation.dart';

/// Adam with bias-corrected first and second moments.
class Adam implements CheckpointOptimizer {
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
  factory Adam.fromJson(Map<String, dynamic> json) {
    requireFormat(json, 'neural_engine_adam');
    try {
      return Adam(
          learningRate: (json['learningRate'] as num).toDouble(),
          beta1: (json['beta1'] as num).toDouble(),
          beta2: (json['beta2'] as num).toDouble(),
          epsilon: (json['epsilon'] as num).toDouble());
    } on Object catch (error) {
      throw FormatException('Invalid Adam configuration: $error');
    }
  }
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_adam',
        'version': 1,
        'learningRate': learningRate,
        'beta1': beta1,
        'beta2': beta2,
        'epsilon': epsilon
      };
  @override
  CheckpointOptimizerState restoreState(
      Map<String, dynamic> json, int parameterCount) {
    requireFormat(json, 'neural_engine_adam_state');
    if (json['step'] is! int || (json['step'] as int) < 0) {
      throw const FormatException('Invalid Adam step.');
    }
    final first = finiteVector(json['firstMoment'], length: parameterCount);
    final second = finiteVector(json['secondMoment'],
        length: parameterCount, nonnegative: true);
    final state = _AdamState(this, parameterCount)..step = json['step'] as int;
    state.m.setAll(0, first);
    state.v.setAll(0, second);
    if (state.step == 0 && [...state.m, ...state.v].any((v) => v != 0)) {
      throw const FormatException(
          'Unstepped Adam state must have zero moments.');
    }
    return state;
  }

  @override
  OptimizerState createState(int parameterCount) =>
      _AdamState(this, parameterCount);
}

class _AdamState implements CheckpointOptimizerState {
  final Adam config;
  final List<double> m;
  final List<double> v;
  int step = 0;
  _AdamState(this.config, int n)
      : m = List.filled(n, 0),
        v = List.filled(n, 0);
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_adam_state',
        'version': 1,
        'step': step,
        'firstMoment': List<double>.of(m),
        'secondMoment': List<double>.of(v)
      };
  @override
  void update(List<double> parameters, List<double> gradients) {
    if (parameters.length != m.length ||
        gradients.length != m.length ||
        [...parameters, ...gradients].any((x) => !x.isFinite)) {
      throw ArgumentError('Invalid Adam update dimensions/values.');
    }
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
    if ([...m, ...v].any((x) => !x.isFinite)) {
      throw StateError('Adam moments overflowed.');
    }
  }
}

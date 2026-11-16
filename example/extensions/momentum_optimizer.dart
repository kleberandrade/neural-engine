import 'package:neural_engine/neural_engine.dart';

/// External optimizer with an application-owned, versioned state codec.
class MomentumOptimizer implements CheckpointOptimizer {
  final double learningRate;
  final double momentum;
  MomentumOptimizer({this.learningRate = 0.05, this.momentum = 0.8}) {
    if (!learningRate.isFinite ||
        learningRate <= 0 ||
        !momentum.isFinite ||
        momentum < 0 ||
        momentum >= 1) {
      throw ArgumentError('Invalid momentum configuration.');
    }
  }
  factory MomentumOptimizer.fromJson(Map<String, dynamic> json) {
    if (json['format'] != 'example_momentum' || json['version'] != 1) {
      throw const FormatException('Unknown momentum format.');
    }
    return MomentumOptimizer(
        learningRate: (json['learningRate'] as num).toDouble(),
        momentum: (json['momentum'] as num).toDouble());
  }
  @override
  Map<String, Object?> toJson() => {
        'format': 'example_momentum',
        'version': 1,
        'learningRate': learningRate,
        'momentum': momentum
      };
  @override
  OptimizerState createState(int parameterCount) =>
      _MomentumState(this, List.filled(parameterCount, 0));
  @override
  CheckpointOptimizerState restoreState(
      Map<String, dynamic> json, int parameterCount) {
    if (json['format'] != 'example_momentum_state' || json['version'] != 1) {
      throw const FormatException('Unknown momentum state.');
    }
    final v = (json['velocity'] as List<dynamic>)
        .map((v) => (v as num).toDouble())
        .toList();
    if (v.length != parameterCount || v.any((x) => !x.isFinite)) {
      throw const FormatException('Invalid momentum state.');
    }
    return _MomentumState(this, v);
  }
}

class _MomentumState implements CheckpointOptimizerState {
  final MomentumOptimizer config;
  final List<double> velocity;
  _MomentumState(this.config, List<double> velocity)
      : velocity = List.of(velocity);
  @override
  void update(List<double> parameters, List<double> gradients) {
    for (var i = 0; i < parameters.length; i++) {
      velocity[i] = config.momentum * velocity[i] + gradients[i];
      parameters[i] -= config.learningRate * velocity[i];
    }
  }

  @override
  Map<String, Object?> toJson() => {
        'format': 'example_momentum_state',
        'version': 1,
        'velocity': List.of(velocity)
      };
}

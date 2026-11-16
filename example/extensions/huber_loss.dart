import 'package:neural_engine/neural_engine.dart';

/// External implementation: quadratic near zero, linear outside delta.
class HuberLoss implements Loss {
  final double delta;
  HuberLoss({this.delta = 1}) {
    if (!delta.isFinite || delta <= 0) {
      throw ArgumentError('Positive delta required.');
    }
  }
  void _check(List<double> p, List<double> t) {
    if (p.isEmpty ||
        p.length != t.length ||
        [...p, ...t].any((v) => !v.isFinite)) {
      throw ArgumentError('Invalid loss vectors.');
    }
  }

  @override
  double value(List<double> predicted, List<double> target) {
    _check(predicted, target);
    var total = 0.0;
    for (var i = 0; i < predicted.length; i++) {
      final d = (predicted[i] - target[i]).abs();
      total += d <= delta ? 0.5 * d * d : delta * (d - 0.5 * delta);
    }
    return total / predicted.length;
  }

  @override
  List<double> gradient(List<double> predicted, List<double> target) {
    _check(predicted, target);
    return List.generate(
        predicted.length,
        (i) =>
            (predicted[i] - target[i]).clamp(-delta, delta) / predicted.length);
  }
}

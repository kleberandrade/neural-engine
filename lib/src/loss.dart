import 'dart:math' as math;

/// Loss extension point. Gradients are with respect to predicted outputs.
abstract interface class Loss {
  double value(List<double> predicted, List<double> target);
  List<double> gradient(List<double> predicted, List<double> target);
}

void _validate(List<double> p, List<double> t) {
  if (p.isEmpty ||
      p.length != t.length ||
      [...p, ...t].any((x) => !x.isFinite)) {
    throw ArgumentError(
      'Predictions and targets must have matching finite values.',
    );
  }
}

/// Mean squared error, averaged over output coordinates.
class MeanSquaredError implements Loss {
  const MeanSquaredError();
  @override
  double value(List<double> predicted, List<double> target) {
    _validate(predicted, target);
    var sum = 0.0;
    for (var i = 0; i < predicted.length; i++) {
      final d = predicted[i] - target[i];
      sum += d * d;
    }
    return sum / predicted.length;
  }

  @override
  List<double> gradient(List<double> predicted, List<double> target) {
    _validate(predicted, target);
    return List.generate(
      predicted.length,
      (i) => 2 * (predicted[i] - target[i]) / predicted.length,
    );
  }
}

/// Binary cross entropy over probabilities; use with a sigmoid output.
/// Training fuses sigmoid + BCE in logit space for numerical stability.
class BinaryCrossEntropy implements Loss {
  const BinaryCrossEntropy();
  @override
  double value(List<double> predicted, List<double> target) {
    _checkProbabilities(predicted, target);
    var sum = 0.0;
    for (var i = 0; i < predicted.length; i++) {
      final p = predicted[i].clamp(1e-15, 1 - 1e-15);
      sum -= target[i] * math.log(p) + (1 - target[i]) * math.log(1 - p);
    }
    return sum / predicted.length;
  }

  @override
  List<double> gradient(List<double> predicted, List<double> target) {
    _checkProbabilities(predicted, target);
    return List.generate(predicted.length, (i) {
      final p = predicted[i].clamp(1e-15, 1 - 1e-15);
      return (p - target[i]) / (p * (1 - p) * predicted.length);
    });
  }
}

/// Categorical cross entropy for softmax outputs and distributions summing to 1.
/// Training fuses softmax + CCE using log-sum-exp.
class CategoricalCrossEntropy implements Loss {
  const CategoricalCrossEntropy();
  @override
  double value(List<double> predicted, List<double> target) {
    _checkCategorical(predicted, target);
    var sum = 0.0;
    for (var i = 0; i < predicted.length; i++) {
      sum -= target[i] * math.log(predicted[i].clamp(1e-15, 1.0));
    }
    return sum;
  }

  @override
  List<double> gradient(List<double> predicted, List<double> target) {
    _checkCategorical(predicted, target);
    return List.generate(
      predicted.length,
      (i) => -target[i] / predicted[i].clamp(1e-15, 1.0),
    );
  }
}

void _checkProbabilities(List<double> p, List<double> t) {
  _validate(p, t);
  if ([...p, ...t].any((v) => v < 0 || v > 1)) {
    throw ArgumentError('Probabilities and targets must be in [0, 1].');
  }
}

void _checkCategorical(List<double> p, List<double> t) {
  _checkProbabilities(p, t);
  if ((p.reduce((a, b) => a + b) - 1).abs() > 1e-9 ||
      (t.reduce((a, b) => a + b) - 1).abs() > 1e-9) {
    throw ArgumentError('Categorical distributions must sum to 1.');
  }
}

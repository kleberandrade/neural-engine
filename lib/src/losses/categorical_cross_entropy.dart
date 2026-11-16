import 'dart:math' as math;
import 'loss.dart';
import 'loss_validation.dart';

/// Categorical cross entropy for softmax outputs and distributions summing to 1.
/// Training fuses softmax + CCE using log-sum-exp.
class CategoricalCrossEntropy implements Loss {
  const CategoricalCrossEntropy();
  @override
  double value(List<double> predicted, List<double> target) {
    checkCategorical(predicted, target);
    var sum = 0.0;
    for (var i = 0; i < predicted.length; i++) {
      sum -= target[i] * math.log(predicted[i].clamp(1e-15, 1.0));
    }
    return sum;
  }

  @override
  List<double> gradient(List<double> predicted, List<double> target) {
    checkCategorical(predicted, target);
    return List.generate(
      predicted.length,
      (i) => -target[i] / predicted[i].clamp(1e-15, 1.0),
    );
  }
}

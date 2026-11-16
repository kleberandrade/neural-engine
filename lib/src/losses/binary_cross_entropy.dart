import 'dart:math' as math;
import 'loss.dart';
import 'loss_validation.dart';

/// Binary cross entropy over probabilities; use with a sigmoid output.
/// Training fuses sigmoid + BCE in logit space for numerical stability.
class BinaryCrossEntropy implements Loss {
  const BinaryCrossEntropy();
  @override
  double value(List<double> predicted, List<double> target) {
    checkProbabilities(predicted, target);
    var sum = 0.0;
    for (var i = 0; i < predicted.length; i++) {
      final p = predicted[i].clamp(1e-15, 1 - 1e-15);
      sum -= target[i] * math.log(p) + (1 - target[i]) * math.log(1 - p);
    }
    return sum / predicted.length;
  }

  @override
  List<double> gradient(List<double> predicted, List<double> target) {
    checkProbabilities(predicted, target);
    return List.generate(predicted.length, (i) {
      final p = predicted[i].clamp(1e-15, 1 - 1e-15);
      return (p - target[i]) / (p * (1 - p) * predicted.length);
    });
  }
}

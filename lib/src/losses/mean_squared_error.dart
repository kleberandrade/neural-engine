import 'loss.dart';
import 'loss_validation.dart';

/// Mean squared error, averaged over output coordinates.
class MeanSquaredError implements Loss {
  const MeanSquaredError();
  @override
  double value(List<double> predicted, List<double> target) {
    validateLossVectors(predicted, target);
    var sum = 0.0;
    for (var i = 0; i < predicted.length; i++) {
      final d = predicted[i] - target[i];
      sum += d * d;
    }
    return sum / predicted.length;
  }

  @override
  List<double> gradient(List<double> predicted, List<double> target) {
    validateLossVectors(predicted, target);
    return List.generate(
      predicted.length,
      (i) => 2 * (predicted[i] - target[i]) / predicted.length,
    );
  }
}

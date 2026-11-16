import 'dart:math' as math;

/// Scalar metrics; flatten coordinates first to report reconstruction errors.
class RegressionMetrics {
  final double mse;
  final double mae;
  final double rSquared;
  double get rmse => math.sqrt(mse);
  const RegressionMetrics._(this.mse, this.mae, this.rSquared);
  factory RegressionMetrics(
      {required List<double> targets, required List<double> predictions}) {
    if (targets.isEmpty ||
        targets.length != predictions.length ||
        [...targets, ...predictions].any((v) => !v.isFinite)) {
      throw ArgumentError('Expected matching finite observations.');
    }
    final mean = targets.fold<double>(0, (s, v) => s + v / targets.length);
    var squared = 0.0;
    var absolute = 0.0;
    var variance = 0.0;
    for (var i = 0; i < targets.length; i++) {
      final d = targets[i] - predictions[i];
      squared += d * d;
      absolute += d.abs();
      variance += (targets[i] - mean) * (targets[i] - mean);
    }
    if (!squared.isFinite || !absolute.isFinite || !variance.isFinite) {
      throw ArgumentError('Metric overflow.');
    }
    return RegressionMetrics._(
        squared / targets.length,
        absolute / targets.length,
        variance == 0 ? (squared == 0 ? 1.0 : 0.0) : 1 - squared / variance);
  }
}

import 'dart:math' as math;
import 'feature_transform.dart';
import '../contracts/json_model.dart';
import '../persistence/json_validation.dart';

/// Maps training min/max to 0/1 without clipping held-out values.
class MinMaxScaler implements FeatureTransform, JsonModel {
  final List<double> minima;
  final List<double> ranges;
  MinMaxScaler._(List<double> minima, List<double> ranges)
      : minima = List.unmodifiable(minima),
        ranges = List.unmodifiable(ranges);

  /// Restores fitted training statistics without fitting on new observations.
  factory MinMaxScaler.fromJson(Map<String, dynamic> json) {
    requireFormat(json, 'neural_engine_min_max_scaler');
    final first = finiteVector(json['minima']);
    final second =
        finiteVector(json['ranges'], length: first.length, positive: true);
    return MinMaxScaler._(first, second);
  }
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_min_max_scaler',
        'version': 1,
        'minima': List<double>.of(minima),
        'ranges': List<double>.of(ranges)
      };

  factory MinMaxScaler.fit(List<List<double>> training) {
    if (training.isEmpty || training.first.isEmpty) {
      throw ArgumentError('Empty training data.');
    }
    final low = List<double>.of(training.first);
    final high = List<double>.of(low);
    for (final row in training) {
      if (row.length != low.length || row.any((v) => !v.isFinite)) {
        throw ArgumentError('Invalid training features.');
      }
      for (var i = 0; i < low.length; i++) {
        low[i] = math.min(low[i], row[i]);
        high[i] = math.max(high[i], row[i]);
      }
    }
    final ranges = List.generate(
        low.length, (i) => high[i] == low[i] ? 1.0 : high[i] - low[i]);
    if (ranges.any((v) => !v.isFinite)) {
      throw ArgumentError('Feature range overflow.');
    }
    return MinMaxScaler._(low, ranges);
  }
  void _check(List<double> row) {
    if (row.length != minima.length || row.any((v) => !v.isFinite)) {
      throw ArgumentError('Invalid features.');
    }
  }

  @override
  List<double> transform(List<double> input) {
    _check(input);
    return List.generate(
        input.length, (i) => (input[i] - minima[i]) / ranges[i]);
  }

  @override
  List<double> inverseTransform(List<double> input) {
    _check(input);
    return List.generate(input.length, (i) => input[i] * ranges[i] + minima[i]);
  }
}

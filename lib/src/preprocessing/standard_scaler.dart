import 'dart:math' as math;
import 'feature_transform.dart';
import '../contracts/json_model.dart';
import '../persistence/json_validation.dart';

/// Population mean/std fitted with Welford's algorithm; constant scales are 1.
class StandardScaler implements FeatureTransform, JsonModel {
  final List<double> means;
  final List<double> scales;
  StandardScaler._(List<double> means, List<double> scales)
      : means = List.unmodifiable(means),
        scales = List.unmodifiable(scales);

  /// Restores fitted training statistics without fitting on new observations.
  factory StandardScaler.fromJson(Map<String, dynamic> json) {
    requireFormat(json, 'neural_engine_standard_scaler');
    final first = finiteVector(json['means']);
    final second =
        finiteVector(json['scales'], length: first.length, positive: true);
    return StandardScaler._(first, second);
  }
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_standard_scaler',
        'version': 1,
        'means': List<double>.of(means),
        'scales': List<double>.of(scales)
      };

  factory StandardScaler.fit(List<List<double>> training) {
    if (training.isEmpty || training.first.isEmpty) {
      throw ArgumentError('Empty training data.');
    }
    final means = List<double>.filled(training.first.length, 0);
    final m2 = List<double>.filled(means.length, 0);
    var n = 0;
    for (final row in training) {
      _check(row, means.length);
      n++;
      for (var i = 0; i < means.length; i++) {
        final d = row[i] - means[i];
        means[i] += d / n;
        m2[i] += d * (row[i] - means[i]);
      }
    }
    final scales = m2.map((v) => v == 0 ? 1.0 : math.sqrt(v / n)).toList();
    if ([...means, ...scales].any((v) => !v.isFinite)) {
      throw ArgumentError('Scaler overflow; rescale inputs.');
    }
    return StandardScaler._(means, scales);
  }
  @override
  List<double> transform(List<double> input) {
    _check(input, means.length);
    return List.generate(
        means.length, (i) => (input[i] - means[i]) / scales[i]);
  }

  @override
  List<double> inverseTransform(List<double> input) {
    _check(input, means.length);
    return List.generate(means.length, (i) => input[i] * scales[i] + means[i]);
  }
}

void _check(List<double> row, int n) {
  if (row.length != n || row.any((v) => !v.isFinite)) {
    throw ArgumentError('Expected $n finite features.');
  }
}

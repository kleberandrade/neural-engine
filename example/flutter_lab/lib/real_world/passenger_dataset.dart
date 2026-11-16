import 'dart:math' as math;
import 'package:neural_engine/neural_engine.dart';
import 'data_partition.dart';
import 'air_passengers_data.dart';

/// Chronological targets, one-step rolling-origin prediction with observed lags.
class PassengerDataset {
  static const lookback = 12;
  late final List<String> months;
  late final List<double> values;
  late final StandardScaler scaler;
  late final DataPartition<List<List<double>>> train, validation, test;
  PassengerDataset() {
    final rows = airPassengersCsv
        .trim()
        .split('\n')
        .skip(1)
        .map((s) => s.split(','))
        .toList();
    months = rows.map((r) => r.first).toList();
    values = rows.map((r) => double.parse(r.last)).toList();
    // Fit only observations through Dec 1956; no validation/test statistics.
    scaler =
        StandardScaler.fit(values.take(96).map((v) => [math.log(v)]).toList());
    double scale(double v) => scaler.transform([math.log(v)]).single;
    DataPartition<List<List<double>>> partition(int start, int end) {
      final ids = [for (var i = start; i < end; i++) i];
      return DataPartition(ids, [
        for (final id in ids)
          [
            for (var t = id - lookback; t < id; t++) [scale(values[t])]
          ]
      ], [
        for (final id in ids) [scale(values[id])]
      ]);
    }

    train = partition(lookback, 96); // Jan 1950-Dec 1956 targets.
    validation = partition(96, 120); // Jan 1957-Dec 1958 targets.
    test = partition(120, 144); // Jan 1959-Dec 1960 targets.
  }
  double unscale(double value) =>
      math.exp(scaler.inverseTransform([value]).single);
}

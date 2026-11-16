import 'dart:math' as math;
import 'package:neural_engine/neural_engine.dart';
import 'air_passengers_data.dart';

/// Validation-only experiment. The published 1959-1960 test is not parsed.
class ForecastValidation {
  final List<double> observations;
  late final StandardScaler scaler;
  static const trainEnd = 96;
  static const validationEnd = 120;
  static const lookback = 12;
  static const candidates = [
    (hidden: 4, epochs: 40),
    (hidden: 4, epochs: 100),
    (hidden: 8, epochs: 40),
    (hidden: 8, epochs: 100),
  ];

  ForecastValidation({List<double>? observations})
      : observations = List.unmodifiable(observations ??
            airPassengersCsv
                .trim()
                .split('\n')
                .skip(1)
                .take(validationEnd)
                .map((line) => double.parse(line.split(',').last))) {
    if (this.observations.length != validationEnd ||
        this.observations.any((v) => !v.isFinite || v <= 0)) {
      throw ArgumentError(
          'Expected positive observations through Dec 1958 only.');
    }
    scaler = StandardScaler.fit(this
        .observations
        .take(trainEnd)
        .map((value) => [math.log(value)])
        .toList());
  }

  double _scale(double value) => scaler.transform([math.log(value)]).single;
  double _unscale(double value) =>
      math.exp(scaler.inverseTransform([value]).single);
  List<List<double>> _window(List<double> history) =>
      history.skip(history.length - lookback).map((v) => [_scale(v)]).toList();

  /// Recursive mode consumes predictions after Dec 1956; rolling mode consumes
  /// each observed validation target only AFTER predicting that month.
  List<double> predict(double Function(List<List<double>>) predictScaled,
      {required bool recursive}) {
    final history = observations.take(trainEnd).toList();
    final predictions = <double>[];
    for (var month = trainEnd; month < validationEnd; month++) {
      final scaled = predictScaled(_window(history));
      if (!scaled.isFinite) throw StateError('Nonfinite forecast.');
      final prediction = _unscale(scaled);
      if (!prediction.isFinite || prediction <= 0) {
        throw StateError('Nonfinite or nonpositive forecast.');
      }
      predictions.add(prediction);
      history.add(recursive ? prediction : observations[month]);
    }
    return predictions;
  }

  Map<String, double> _metrics(List<double> predictions) {
    final metrics = RegressionMetrics(
        targets: observations.skip(trainEnd).toList(),
        predictions: predictions);
    return {'maeThousands': metrics.mae, 'rmseThousands': metrics.rmse};
  }

  Future<Map<String, Object?>> run() async {
    final inputs = [
      for (var t = lookback; t < trainEnd; t++)
        _window(observations.take(t).toList())
    ];
    final targets = [
      for (var t = lookback; t < trainEnd; t++) [_scale(observations[t])]
    ];
    final rows = <Map<String, Object?>>[];
    var selected = 0;
    var best = double.infinity;
    for (final candidate in candidates) {
      final session = TrainingSession<List<List<double>>>(
          model: RecurrentNetwork(
              inputSize: 1,
              hiddenSize: candidate.hidden,
              outputSize: 1,
              kind: RecurrentKind.gru,
              seed: 42),
          optimizer: Adam(learningRate: 0.01),
          seed: 42);
      final result = await session.fitAsync(
          inputs: inputs,
          targets: targets,
          loss: const MeanSquaredError(),
          epochs: candidate.epochs,
          batchSize: 12,
          maxGradientNorm: 1,
          shuffle: false);
      final model = RecurrentNetwork.fromJson(result.checkpoint.model);
      double infer(List<List<double>> x) => model.predict(x).single;
      final rolling = _metrics(predict(infer, recursive: false));
      final recursive = _metrics(predict(infer, recursive: true));
      if (rolling['maeThousands']! < best) {
        best = rolling['maeThousands']!;
        selected = rows.length;
      }
      rows.add({
        'hidden': candidate.hidden,
        'epochs': candidate.epochs,
        'rollingValidation': rolling,
        'recursiveValidation': recursive
      });
    }
    return {
      'protocolVersion': 1,
      'trainTargets': 84,
      'validationTargets': 24,
      'trainEnd': '1956-12',
      'validationEnd': '1958-12',
      'testEvaluated': false,
      'selection':
          'Minimum rolling validation MAE; stable candidate order breaks ties. Recursive scores are diagnostic only.',
      'selectedCandidateIndex': selected,
      'candidates': rows,
      'baselines': {
        'rollingPreviousMonth': _metrics([
          for (var t = trainEnd; t < validationEnd; t++) observations[t - 1]
        ]),
        'rollingPreviousYear': _metrics([
          for (var t = trainEnd; t < validationEnd; t++) observations[t - 12]
        ]),
        'recursiveLastMonth': _metrics(
            List.filled(validationEnd - trainEnd, observations[trainEnd - 1])),
        'recursiveSeasonalCycle': _metrics([
          for (var t = trainEnd; t < validationEnd; t++)
            observations[trainEnd - 12 + (t - trainEnd) % 12]
        ]),
      },
      'note':
          'Candidate selection uses validation; these scores are not an unbiased test estimate. The previously published 1959-1960 test is excluded. No claim of improved generalization.',
    };
  }
}

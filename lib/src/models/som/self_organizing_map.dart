import 'dart:math' as math;
import '../../contracts/json_model.dart';
import '../../contracts/unsupervised_model.dart';
import 'som_match.dart';
import 'som_history.dart';

/// Kohonen self-organizing map with Euclidean BMU and Gaussian neighborhood.
/// Initialize with unit-range weights; scale each input feature before training.
class SelfOrganizingMap implements JsonModel, UnsupervisedModel<List<double>> {
  final int rows;
  final int columns;
  final int inputSize;
  final int? seed;
  late List<List<double>> _weights;

  SelfOrganizingMap(
      {required this.rows,
      required this.columns,
      required this.inputSize,
      this.seed}) {
    if (rows <= 0 || columns <= 0 || inputSize <= 0) {
      throw ArgumentError('SOM grid and input dimensions must be positive.');
    }
    final random = math.Random(seed);
    _weights = List.generate(rows * columns,
        (_) => List.generate(inputSize, (_) => random.nextDouble()));
  }

  /// Row-major neurons, each holding an independent immutable prototype.
  List<List<double>> get weights =>
      List.unmodifiable(_weights.map((w) => List<double>.unmodifiable(w)));
  set weights(List<List<double>> values) {
    if (values.length != rows * columns) {
      throw ArgumentError('Expected ${rows * columns} prototypes.');
    }
    for (final value in values) {
      _validate(value);
    }
    _weights = values.map(List<double>.of).toList();
  }

  void _validate(List<double> sample) {
    if (sample.length != inputSize || sample.any((v) => !v.isFinite)) {
      throw ArgumentError('SOM sample must have $inputSize finite values.');
    }
  }

  /// Finds the nearest prototype; exact ties select the first row-major neuron.
  SomMatch winner(List<double> input) {
    _validate(input);
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var n = 0; n < _weights.length; n++) {
      var squared = 0.0;
      for (var i = 0; i < inputSize; i++) {
        final d = input[i] - _weights[n][i];
        squared += d * d;
      }
      if (!squared.isFinite) {
        throw StateError('Distance overflow; rescale SOM inputs.');
      }
      if (squared < bestDistance) {
        bestDistance = squared;
        bestIndex = n;
      }
    }
    return SomMatch(
        bestIndex ~/ columns, bestIndex % columns, math.sqrt(bestDistance));
  }

  @override
  double quantizationError(List<List<double>> inputs) {
    if (inputs.isEmpty) throw ArgumentError('SOM data must be nonempty.');
    var total = 0.0;
    for (final input in inputs) {
      total += winner(input).distance / inputs.length;
    }
    if (!total.isFinite) throw StateError('Nonfinite quantization error.');
    return total;
  }

  /// Online updates with exponential learning-rate/radius decay per sample.
  /// Epochs=1 and a single sample use the initial values; no labels are needed.
  SomHistory fit(List<List<double>> inputs,
      {int epochs = 100,
      double learningRate = 0.5,
      double finalLearningRate = 0.05,
      double? radius,
      double finalRadius = 0.5,
      bool shuffle = true}) {
    final initialRadius = radius ?? math.max(rows, columns) / 2;
    if (epochs <= 0 ||
        !learningRate.isFinite ||
        learningRate <= 0 ||
        learningRate > 1 ||
        !finalLearningRate.isFinite ||
        finalLearningRate <= 0 ||
        finalLearningRate > 1 ||
        !initialRadius.isFinite ||
        initialRadius <= 0 ||
        !finalRadius.isFinite ||
        finalRadius <= 0) {
      throw ArgumentError('Invalid SOM training schedule.');
    }
    quantizationError(inputs); // Validate all samples before the first update.
    final order = List.generate(inputs.length, (i) => i);
    final random = math.Random(seed);
    final errors = <double>[];
    var step = 0;
    final totalSteps = epochs * inputs.length;
    for (var epoch = 0; epoch < epochs; epoch++) {
      if (shuffle) order.shuffle(random);
      for (final index in order) {
        final t = totalSteps == 1 ? 0.0 : step / (totalSteps - 1);
        final rate = math.exp(
            (1 - t) * math.log(learningRate) + t * math.log(finalLearningRate));
        final sigma = math
            .exp((1 - t) * math.log(initialRadius) + t * math.log(finalRadius));
        final input = inputs[index];
        final bmu = winner(input);
        final candidate = weights.map(List<double>.of).toList();
        for (var n = 0; n < candidate.length; n++) {
          final dr = n ~/ columns - bmu.row;
          final dc = n % columns - bmu.column;
          final latticeDistance = dr * dr + dc * dc;
          // A zero lattice distance must remain 1 even for tiny radii.
          final influence = latticeDistance == 0
              ? 1.0
              : math.exp(-0.5 * (latticeDistance / sigma) / sigma);
          final amount = rate * influence;
          for (var i = 0; i < inputSize; i++) {
            candidate[n][i] = (1 - amount) * _weights[n][i] + amount * input[i];
          }
        }
        weights = candidate;
        step++;
      }
      errors.add(quantizationError(inputs));
    }
    return SomHistory(errors);
  }

  /// Mean Euclidean prototype distance to four directly adjacent grid cells.
  /// A one-cell map has distance zero; high values can indicate cluster borders.
  List<List<double>> uMatrix() => List.unmodifiable(List.generate(
      rows,
      (r) => List<double>.unmodifiable(List.generate(columns, (c) {
            var sum = 0.0;
            var count = 0;
            for (final neighbor in [
              (r - 1, c),
              (r + 1, c),
              (r, c - 1),
              (r, c + 1)
            ]) {
              if (neighbor.$1 < 0 ||
                  neighbor.$1 >= rows ||
                  neighbor.$2 < 0 ||
                  neighbor.$2 >= columns) {
                continue;
              }
              final a = _weights[r * columns + c],
                  b = _weights[neighbor.$1 * columns + neighbor.$2];
              var squared = 0.0;
              for (var i = 0; i < inputSize; i++) {
                final d = a[i] - b[i];
                squared += d * d;
              }
              sum += math.sqrt(squared);
              count++;
            }
            return count == 0 ? 0.0 : sum / count;
          }))));

  /// BMU sample counts; rows/columns match the prototype grid, not class labels.
  List<List<int>> hitMap(List<List<double>> inputs) {
    final counts = List.generate(rows, (_) => List<int>.filled(columns, 0));
    for (final input in inputs) {
      final match = winner(input);
      counts[match.row][match.column]++;
    }
    return List.unmodifiable(counts.map((r) => List<int>.unmodifiable(r)));
  }

  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_som',
        'version': 1,
        'rows': rows,
        'columns': columns,
        'inputSize': inputSize,
        'seed': seed,
        'weights': weights
      };

  factory SelfOrganizingMap.fromJson(Map<String, dynamic> json) {
    try {
      if (json['format'] != 'neural_engine_som' || json['version'] != 1) {
        throw const FormatException('Unsupported SOM format/version.');
      }
      final map = SelfOrganizingMap(
          rows: json['rows'] as int,
          columns: json['columns'] as int,
          inputSize: json['inputSize'] as int,
          seed: json['seed'] as int?);
      map.weights = (json['weights'] as List<dynamic>)
          .map((w) =>
              (w as List<dynamic>).map((v) => (v as num).toDouble()).toList())
          .toList();
      return map;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid SOM model: $error');
    }
  }
}

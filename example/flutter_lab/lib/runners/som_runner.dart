import 'package:neural_engine/neural_engine.dart';
import '../datasets.dart';

Map<String, Object?> trainSom() {
  final samples = colorDataset();
  final model = SelfOrganizingMap(rows: 6, columns: 6, inputSize: 3, seed: 42);
  final before = model.weights;
  final initial = model.quantizationError(samples);
  final history = model.fit(samples, epochs: 80, radius: 3, finalRadius: 0.4);
  return {
    'curve': history.quantizationErrors,
    'before': before,
    'weights': model.weights,
    'distances': model.uMatrix().expand((r) => r).toList(),
    'hits': model
        .hitMap(samples)
        .expand((r) => r)
        .map((v) => v.toDouble())
        .toList(),
    'summary':
        'Quantization error: ${initial.toStringAsFixed(4)} → ${history.quantizationErrors.last.toStringAsFixed(4)}',
    'matches': [
      for (final color in <List<double>>[
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1]
      ])
        'RGB $color → (${model.winner(color).row}, ${model.winner(color).column})'
    ]
  };
}

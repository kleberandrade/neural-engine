import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
// Share pure Dart fixtures with the nested Flutter example, without Flutter imports.
// ignore: avoid_relative_lib_imports
import 'flutter_lab/lib/datasets.dart';

void main() {
  final colors = colorDataset();
  final map = SelfOrganizingMap(rows: 6, columns: 6, inputSize: 3, seed: 42);
  final before = map.quantizationError(colors);
  final history = map.fit(colors, epochs: 80, radius: 3, finalRadius: 0.4);
  final after = history.quantizationErrors.last;
  print('SOM quantization error: $before -> $after');
  for (final color in <List<double>>[
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1]
  ]) {
    final match = map.winner(color);
    print(
        'RGB $color -> row=${match.row}, column=${match.column}, distance=${match.distance}');
  }
  final restored = SelfOrganizingMap.fromJson(
      jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>);
  if (after >= before ||
      restored.winner([1, 0, 0]).distance != map.winner([1, 0, 0]).distance) {
    throw StateError('SOM learning/roundtrip check failed.');
  }
}

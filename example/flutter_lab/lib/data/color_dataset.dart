import 'dart:math' as math;

/// RGB anchors perturbed inside the unit cube, no labels used by SOM training.
List<List<double>> colorDataset({int seed = 42}) {
  final random = math.Random(seed);
  final anchors = <List<double>>[
    [0.95, 0.1, 0.1],
    [0.1, 0.95, 0.1],
    [0.1, 0.1, 0.95],
    [0.95, 0.95, 0.1],
    [0.95, 0.1, 0.95],
    [0.1, 0.95, 0.95],
  ];
  return [
    for (final anchor in anchors)
      for (var i = 0; i < 8; i++)
        anchor
            .map(
                (v) => (v + (random.nextDouble() - 0.5) * 0.12).clamp(0.0, 1.0))
            .toList()
  ];
}

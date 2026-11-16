import 'dart:math' as math;

const reconstructionPatterns = <List<double>>[
  [1, 1, 0, 0, 0, 0, 0, 0],
  [0, 0, 1, 1, 0, 0, 0, 0],
  [0, 0, 0, 0, 1, 1, 0, 0],
  [0, 0, 0, 0, 0, 0, 1, 1],
];

({List<List<double>> inputs, List<List<double>> targets}) reconstructionDataset(
    {int seed = 42}) {
  final random = math.Random(seed);
  final inputs = <List<double>>[];
  final targets = <List<double>>[];
  for (final pattern in reconstructionPatterns) {
    for (var i = 0; i < 5; i++) {
      inputs.add(pattern
          .map((v) => v == 0
              ? random.nextDouble() * 0.15
              : 0.85 + random.nextDouble() * 0.15)
          .toList());
      targets.add(List.of(pattern));
    }
  }
  return (inputs: inputs, targets: targets);
}

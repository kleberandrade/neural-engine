import 'dart:math' as math;

/// Sampled phases of the same sine family; test phases interleave training.
({List<List<List<double>>> inputs, List<List<double>> targets}) sequenceDataset(
    {bool test = false}) {
  final inputs = <List<List<double>>>[];
  final targets = <List<double>>[];
  for (var i = 0; i < 24; i++) {
    final phase = 2 * math.pi * (i + (test ? 0.5 : 0)) / 24;
    inputs.add([
      for (var t = 0; t < 6; t++) [math.sin(phase + t * 0.25)]
    ]);
    targets.add([math.sin(phase + 6 * 0.25)]);
  }
  return (inputs: inputs, targets: targets);
}

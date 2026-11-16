import 'dart:math' as math;
import 'package:neural_engine/neural_engine.dart';

/// Generated 6x6 grayscale bars. Classes: 0=vertical, 1=horizontal.
/// A different seed changes noise, while positions and classes are shared.
({List<ImageTensor> images, List<List<double>> targets}) barDataset(
    {int seed = 42, int repetitions = 2}) {
  final random = math.Random(seed);
  final images = <ImageTensor>[];
  final targets = <List<double>>[];
  for (var repeat = 0; repeat < repetitions; repeat++) {
    for (var vertical in [true, false]) {
      for (var position = 1; position <= 4; position++) {
        images.add(ImageTensor(
            height: 6,
            width: 6,
            channels: 1,
            values: List.generate(36, (i) {
              final line = vertical ? i % 6 == position : i ~/ 6 == position;
              return line
                  ? 0.85 + random.nextDouble() * 0.15
                  : random.nextDouble() * 0.15;
            })));
        targets.add(vertical ? [1, 0] : [0, 1]);
      }
    }
  }
  return (images: images, targets: targets);
}

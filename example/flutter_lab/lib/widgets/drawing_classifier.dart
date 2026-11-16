// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:neural_engine/neural_engine.dart';

class DrawingClassifier extends StatefulWidget {
  final ConvolutionalNetwork model;
  const DrawingClassifier({required this.model, super.key});
  @override
  State<DrawingClassifier> createState() => _DrawingClassifierState();
}

class _DrawingClassifierState extends State<DrawingClassifier> {
  final _pixels = List<double>.filled(36, 0);
  List<double>? _prediction;
  void _paint(Offset point) {
    final x = (point.dx / 40).floor(), y = (point.dy / 40).floor();
    if (x < 0 || x >= 6 || y < 0 || y >= 6) return;
    setState(() {
      _pixels[y * 6 + x] = 1;
      _prediction = null;
    });
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        const Text('Draw a 6×6 pattern'),
        const Text(
            'This model learned only vertical/horizontal bars. Arbitrary drawings can be outside its training distribution.'),
        const SizedBox(height: 12),
        GestureDetector(
            key: const ValueKey('drawing-grid'),
            onTapDown: (d) => _paint(d.localPosition),
            onPanUpdate: (d) => _paint(d.localPosition),
            child: SizedBox(
                width: 240,
                height: 240,
                child: GridView.count(
                    crossAxisCount: 6,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    children: [
                      for (final value in _pixels)
                        ColoredBox(
                            color:
                                value == 0 ? Colors.black : Colors.cyanAccent)
                    ]))),
        Wrap(spacing: 12, children: [
          OutlinedButton(
              onPressed: () => setState(() {
                    _pixels.fillRange(0, 36, 0);
                    _prediction = null;
                  }),
              child: const Text('Clear drawing')),
          FilledButton(
              key: const ValueKey('classify-drawing'),
              onPressed: () => setState(() => _prediction = widget.model
                  .predict(ImageTensor(
                      height: 6, width: 6, channels: 1, values: _pixels))),
              child: const Text('Classify drawing')),
        ]),
        if (_prediction != null)
          Text(
              'Drawing probabilities [vertical, horizontal]: ${_prediction!.map((v) => v.toStringAsFixed(4)).join(', ')}'),
      ]);
}

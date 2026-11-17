import '../l10n/lab_copy.dart';
import 'package:material_ui/material_ui.dart';
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
  void _paint(Offset point, double extent) {
    final pitch = (extent + 1) / 6;
    final x = (point.dx / pitch).floor(), y = (point.dy / pitch).floor();
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
        const LabText('Draw a 6×6 pattern'),
        const LabText(
            'Tap or use Tab and Enter to toggle pixels; drag to draw. This model learned only vertical/horizontal bars. Arbitrary drawings can be outside its training distribution.'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final extent =
              constraints.maxWidth < 293 ? constraints.maxWidth : 293.0;
          return GestureDetector(
              key: const ValueKey('drawing-grid'),
              onPanStart: (d) => _paint(d.localPosition, extent),
              onPanUpdate: (d) => _paint(d.localPosition, extent),
              child: SizedBox(
                  width: extent,
                  height: extent,
                  child: GridView.count(
                      crossAxisCount: 6,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                      children: [
                        for (var i = 0; i < _pixels.length; i++)
                          Semantics(
                              label: tr(context,
                                  'Pixel row ${i ~/ 6 + 1}, column ${i % 6 + 1}'),
                              toggled: _pixels[i] == 1,
                              child: InkWell(
                                  key: ValueKey('drawing-pixel-$i'),
                                  onTap: () => setState(() {
                                        _pixels[i] = _pixels[i] == 0 ? 1 : 0;
                                        _prediction = null;
                                      }),
                                  child: ColoredBox(
                                      color: _pixels[i] == 0
                                          ? Colors.black
                                          : Colors.cyanAccent))),
                      ])));
        }),
        Wrap(spacing: 12, children: [
          OutlinedButton(
              onPressed: () => setState(() {
                    _pixels.fillRange(0, 36, 0);
                    _prediction = null;
                  }),
              child: const LabText('Clear drawing')),
          FilledButton(
              key: const ValueKey('classify-drawing'),
              onPressed: () => setState(() => _prediction = widget.model
                  .predict(ImageTensor(
                      height: 6, width: 6, channels: 1, values: _pixels))),
              child: const LabText('Classify drawing')),
        ]),
        if (_prediction != null)
          LabText(
              'Drawing probabilities [vertical, horizontal]: ${_prediction!.map((v) => v.toStringAsFixed(4)).join(', ')}'),
      ]);
}

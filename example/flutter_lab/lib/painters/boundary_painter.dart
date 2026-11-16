// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:neural_engine/neural_engine.dart';
import '../data/xor_dataset.dart';
import 'plot_text.dart';

class BoundaryPainter extends CustomPainter {
  final NeuralNetwork network;
  BoundaryPainter(this.network);
  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(30, 12, size.width - 45, size.height - 40);
    const cells = 36;
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final p =
            network.predict([x / (cells - 1), 1 - y / (cells - 1)]).single;
        canvas.drawRect(
            Rect.fromLTWH(
                area.left + x * area.width / cells,
                area.top + y * area.height / cells,
                area.width / cells + 0.5,
                area.height / cells + 0.5),
            Paint()
              ..color = Color.lerp(
                  Colors.blue.shade800, Colors.deepOrange.shade400, p)!);
      }
    }
    for (var i = 0; i < 4; i++) {
      final position = Offset(area.left + xorInputs[i][0] * area.width,
          area.bottom - xorInputs[i][1] * area.height);
      canvas.drawCircle(position, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
          position,
          5,
          Paint()
            ..color = xorTargets[i][0] == 0 ? Colors.blue : Colors.deepOrange);
    }
    paintPlotLabel(canvas, 'x₂', Offset(0, area.top));
    paintPlotLabel(canvas, '0', Offset(area.left, area.bottom + 8));
    paintPlotLabel(canvas, '1 · x₁', Offset(area.right - 32, area.bottom + 8));
  }

  @override
  bool shouldRepaint(BoundaryPainter old) => network != old.network;
}

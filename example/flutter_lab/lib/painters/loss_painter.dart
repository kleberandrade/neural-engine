// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'plot_text.dart';

class LossPainter extends CustomPainter {
  final List<double> losses;
  LossPainter(this.losses);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke;
    final area = Rect.fromLTWH(38, 12, size.width - 50, size.height - 40);
    canvas.drawRect(area, paint);
    final maxLoss = math.max(0.01, losses.reduce(math.max));
    final path = Path();
    for (var i = 0; i < losses.length; i++) {
      final x = area.left + area.width * i / math.max(1, losses.length - 1);
      final y = area.bottom - area.height * losses[i] / maxLoss;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    paintPlotLabel(canvas, maxLoss.toStringAsFixed(2), Offset(0, area.top));
    paintPlotLabel(canvas, '0', Offset(18, area.bottom - 12));
    paintPlotLabel(canvas, '1', Offset(area.left, area.bottom + 8));
    paintPlotLabel(canvas, '${losses.length} epochs',
        Offset(area.right - 85, area.bottom + 8));
  }

  @override
  bool shouldRepaint(LossPainter old) => !identical(losses, old.losses);
}

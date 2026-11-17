import 'package:material_ui/material_ui.dart';

import 'dart:math' as math;

class CurvePainter extends CustomPainter {
  final List<double> values;
  final List<double> secondary;
  final String epochLabel;
  CurvePainter(this.values,
      {this.secondary = const [], this.epochLabel = 'epochs'});
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = math.max(1e-9, [...values, ...secondary].reduce(math.max));
    final area = Rect.fromLTWH(42, 14, size.width - 56, size.height - 40);
    canvas.drawRect(
        area,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke);
    void curve(List<double> series, Color color, {bool dots = false}) {
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final x = area.left + area.width * i / math.max(1, values.length - 1);
        final y = area.bottom - area.height * series[i] / maxValue;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        if (dots && i % math.max(1, series.length ~/ 10) == 0) {
          canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
        }
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }

    curve(values, const Color(0xFF8DE0CC));
    curve(secondary, const Color(0xFFF2CA86), dots: true);
    for (final item in [
      (maxValue.toStringAsFixed(3), Offset(0, area.top)),
      ('0', Offset(22, area.bottom - 10)),
      ('1', Offset(area.left, area.bottom + 6)),
      (
        '${values.length} $epochLabel',
        Offset(area.right - 90, area.bottom + 6)
      ),
    ]) {
      final text = TextPainter(
          text: TextSpan(
              text: item.$1,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(canvas, item.$2);
    }
  }

  @override
  bool shouldRepaint(CurvePainter old) =>
      !identical(values, old.values) ||
      !identical(secondary, old.secondary) ||
      epochLabel != old.epochLabel;
}

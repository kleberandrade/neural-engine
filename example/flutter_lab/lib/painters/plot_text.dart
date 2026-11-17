import 'package:material_ui/material_ui.dart';

void paintPlotLabel(Canvas canvas, String text, Offset offset) {
  final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      textDirection: TextDirection.ltr)
    ..layout();
  painter.paint(canvas, offset);
}

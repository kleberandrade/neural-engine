// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

void paintPlotLabel(Canvas canvas, String text, Offset offset) {
  final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      textDirection: TextDirection.ltr)
    ..layout();
  painter.paint(canvas, offset);
}

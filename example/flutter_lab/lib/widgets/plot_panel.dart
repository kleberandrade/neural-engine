// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

class PlotPanel extends StatelessWidget {
  final String title;
  final CustomPainter painter;
  const PlotPanel({required this.title, required this.painter});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title),
        const SizedBox(height: 12),
        AspectRatio(aspectRatio: 1.25, child: CustomPaint(painter: painter)),
      ]);
}

// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

class PixelGrid extends StatelessWidget {
  final String title;
  final List<double> values;
  final int columns;
  const PixelGrid(
      {required this.title, required this.values, required this.columns});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 210,
      child: Column(children: [
        Text(title),
        const SizedBox(height: 8),
        GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            children: [
              for (final v in values)
                ColoredBox(
                    color: Color.lerp(
                        Colors.black, Colors.cyanAccent, v.clamp(0.0, 1.0))!)
            ]),
      ]));
}

// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

class ColorMap extends StatelessWidget {
  final String title;
  final List<List<double>> weights;
  const ColorMap({required this.title, required this.weights});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 260,
      child: Column(children: [
        Text(title),
        const SizedBox(height: 8),
        GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            children: [
              for (final w in weights)
                Tooltip(
                    message: w.map((v) => v.toStringAsFixed(2)).join(', '),
                    child: ColoredBox(
                        color: Color.fromRGBO(
                            (w[0] * 255).round().clamp(0, 255),
                            (w[1] * 255).round().clamp(0, 255),
                            (w[2] * 255).round().clamp(0, 255),
                            1)))
            ]),
      ]));
}

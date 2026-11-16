// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Contrast uses min/max, while tooltips show the original numerical values.
class ScalarGrid extends StatelessWidget {
  final String title;
  final List<double> values;
  final int columns;
  const ScalarGrid(
      {required this.title,
      required this.values,
      required this.columns,
      super.key});
  @override
  Widget build(BuildContext context) {
    final low = values.reduce(math.min), high = values.reduce(math.max);
    return Align(
        widthFactor: 1,
        alignment: Alignment.centerLeft,
        child: SizedBox(
            width: 260,
            child: Column(children: [
              Text(title),
              Text(
                  'min ${low.toStringAsFixed(3)} · max ${high.toStringAsFixed(3)}'),
              GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  children: [
                    for (final value in values)
                      Tooltip(
                          message: value.toStringAsFixed(4),
                          child: ColoredBox(
                              color: Color.lerp(
                                  Colors.blue.shade900,
                                  Colors.amber,
                                  high == low
                                      ? 0.0
                                      : (value - low) / (high - low))!))
                  ])
            ])));
  }
}

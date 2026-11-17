// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../painters/curve_painter.dart';

/// Both curves share one vertical scale; text exposes values without color.
class LossChart extends StatelessWidget {
  final List<double> training, validation;
  const LossChart({
    super.key,
    required this.training,
    this.validation = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (training.isEmpty) return const SizedBox.shrink();
    final summary =
        'Training ${training.first.toStringAsFixed(5)} → ${training.last.toStringAsFixed(5)}'
        '${validation.isEmpty ? '' : ' · Validation ${validation.first.toStringAsFixed(5)} → ${validation.last.toStringAsFixed(5)}'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Loss by epoch · current run only'),
        Text(summary),
        if (validation.isNotEmpty)
          const Text('Cyan line: training · Amber line with dots: validation'),
        Semantics(
          image: true,
          label:
              'Loss curve over ${training.length} completed epochs. $summary',
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: CustomPaint(
              painter: CurvePainter(training, secondary: validation),
            ),
          ),
        ),
      ],
    );
  }
}

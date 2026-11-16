@Tags(['benchmark'])
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/benchmarks/responsiveness.dart';

void main() {
  test('record real event-loop, cancellation and memory measurements',
      () async {
    final report = await runResponsiveness(
        host: kIsWeb
            ? 'Flutter test / Chrome headless'
            : 'Flutter test / native headless engine');
    final rows = report['rows']! as List<Map<String, Object?>>;
    expect(rows, hasLength(12));
    for (final row in rows) {
      expect((row['cancellationLatency']! as Map)['samples'], 3);
      expect(
          (row['completedEpochsOnCancel']! as List<int>)
              .every((v) => v >= 2 && v < 100),
          isTrue);
    }
    // These are observations, not timing thresholds: CI machines are variable.
    print('NEURAL_RESPONSIVENESS ${jsonEncode(report)}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

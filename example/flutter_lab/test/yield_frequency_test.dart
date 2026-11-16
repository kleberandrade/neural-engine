@Tags(['benchmark'])
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/benchmarks/yield_frequency.dart';

void main() {
  test('fixed-batch yield policies preserve exact checkpoint arithmetic',
      () async {
    final report = await measureYieldFrequency(
        host: kIsWeb ? 'Flutter Chrome' : 'Flutter native test engine');
    expect(report['rows'], hasLength(10));
    print('NEURAL_YIELD ${jsonEncode(report)}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

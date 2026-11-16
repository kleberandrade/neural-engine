import 'dart:convert';
import 'package:test/test.dart';
// ignore: avoid_relative_lib_imports
import '../example/flutter_lab/lib/runners/checkpoint_runner.dart';

void main() {
  for (final family in ['MLP', 'CNN', 'RNN', 'LSTM', 'GRU']) {
    test('$family Flutter runner saves, loads and exactly resumes', () {
      final saved = runCheckpointDemo({'family': family, 'action': 'start'});
      expect(saved['epochs'], 40);
      final loaded = runCheckpointDemo(
          {'family': family, 'action': 'load', 'json': saved['json']!});
      expect(loaded['predictions'], saved['predictions']);
      expect(loaded['exact'], isTrue);
      expect(loaded['bytes'], utf8.encode(loaded['json']! as String).length);
      final resumed = runCheckpointDemo(
          {'family': family, 'action': 'resume', 'json': loaded['json']!});
      expect(resumed['epochs'], 100);
      expect(resumed['exact'], isTrue);
      expect(resumed['maxDifference'], 0);
      expect(
          () => runCheckpointDemo(
              {'family': family, 'action': 'resume', 'json': resumed['json']!}),
          throwsFormatException);
    });
  }
  test('checkpoint UI runner rejects invalid JSON and wrong family', () {
    expect(
        () => runCheckpointDemo(
            {'family': 'MLP', 'action': 'load', 'json': '{}'}),
        throwsFormatException);
    final saved = runCheckpointDemo({'family': 'MLP', 'action': 'start'});
    expect(
        () => runCheckpointDemo(
            {'family': 'CNN', 'action': 'load', 'json': saved['json']!}),
        throwsFormatException);
  });
}

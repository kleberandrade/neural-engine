import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:neural_engine/neural_engine.dart';
import 'runtime/memory_web.dart'
    if (dart.library.io) 'runtime/memory_native.dart';
import '../runners/async_demo_recipe.dart';

Map<String, Object?> distribution(List<int> values) {
  if (values.isEmpty) {
    return {'samples': 0, 'medianUs': null, 'p95Us': null, 'maxUs': null};
  }
  final sorted = List<int>.of(values)..sort();
  return {
    'samples': sorted.length,
    'medianUs': sorted[sorted.length ~/ 2],
    'p95Us': sorted[((sorted.length - 1) * 0.95).ceil()],
    'maxUs': sorted.last
  };
}

/// Timer delays are an event-loop responsiveness proxy, never rendered FPS.
Future<Map<String, Object?>> runResponsiveness(
    {String host = 'Dart CLI', int repetitions = 3}) async {
  final rows = <Map<String, Object?>>[];
  for (final family in ['MLP', 'CNN', 'GRU']) {
    for (final execution in [
      TrainingExecution.automatic,
      TrainingExecution.cooperative
    ]) {
      for (final batchSize in [1, 8]) {
        final durations = <int>[], cancellationLatencies = <int>[];
        final delays = <int>[];
        var heartbeats = 0;
        int? startBytes, peakBytes, endBytes;
        final epochsAtCancellation = <int>[];
        for (var repeat = 0; repeat < repetitions; repeat++) {
          final recipe = AsyncDemoRecipe(family);
          // Freeze the same recipe and override batch size only.
          AsyncTrainingRequest request(int epochs) {
            final json = recipe.request(recipe.initial, epochs).toJson();
            json['batchSize'] = batchSize;
            return AsyncTrainingRequest.fromJson(json);
          }

          // Warm the model code and worker path, but use fresh weights for measurement.
          await AsyncTrainingTask.start(request(1), execution: execution)
              .result;
          final start = memoryBytes();
          startBytes ??= start;
          if (start != null) peakBytes = math.max(peakBytes ?? 0, start);
          final clock = Stopwatch()..start();
          var lastTick = clock.elapsedMicroseconds;
          final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
            final now = clock.elapsedMicroseconds;
            delays.add(math.max(0, now - lastTick - 1000));
            lastTick = now;
            heartbeats++;
            final memory = memoryBytes();
            if (memory != null) peakBytes = math.max(peakBytes ?? 0, memory);
          });
          try {
            await AsyncTrainingTask.start(request(8), execution: execution)
                .result;
            durations.add(clock.elapsedMicroseconds);
          } finally {
            timer.cancel();
            clock.stop();
          }
          endBytes = memoryBytes();
          if (endBytes != null) peakBytes = math.max(peakBytes ?? 0, endBytes);
          final job =
              AsyncTrainingTask.start(request(100), execution: execution);
          final cancelClock = Stopwatch();
          final subscription = job.progress.listen((p) {
            if (p.epochsThisRun >= 2 && !cancelClock.isRunning) {
              cancelClock.start();
              job.cancel();
            }
          });
          final stopped = await job.result;
          await subscription.cancel();
          if (!stopped.cancelled || !cancelClock.isRunning) {
            throw StateError('Cancellation probe did not stop.');
          }
          cancelClock.stop();
          cancellationLatencies.add(cancelClock.elapsedMicroseconds);
          epochsAtCancellation.add(stopped.checkpoint.epochsCompleted);
        }
        rows.add({
          'family': family,
          'requestedExecution': execution.name,
          'batchSize': batchSize,
          'epochs': 8,
          'repetitions': repetitions,
          'wallTraining': distribution(durations),
          'eventLoopDelay': distribution(delays),
          'heartbeatCount': heartbeats,
          'cancellationLatency': distribution(cancellationLatencies),
          'cancelAfterProgressEpoch': 2,
          'completedEpochsOnCancel': epochsAtCancellation,
          'memoryStartBytes': startBytes,
          'sampledPeakBytes': peakBytes,
          'memoryEndBytes': endBytes
        });
      }
    }
  }
  return {
    'host': host,
    ...runtimeInfo(),
    'seed': 42,
    'timerIntervalUs': 1000,
    'workloads':
        'AsyncDemoRecipe defaults, Adam 0.02, gradient clipping 1; batch size overridden',
    'measurementNotes':
        'One process; sampled memory is not allocated bytes or an exact peak; JS heap and native RSS are incomparable. Wall time includes serialization/startup. Timer delays are not frame times. Three repetitions are descriptive, not confidence intervals.',
    'rows': rows
  };
}

Future<void> main() async {
  final result = await runResponsiveness();
  print('NEURAL_RESPONSIVENESS ${jsonEncode(result)}');
}

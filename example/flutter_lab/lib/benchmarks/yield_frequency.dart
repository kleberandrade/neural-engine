import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:neural_engine/neural_engine.dart';
import '../runners/async_demo_recipe.dart';
import 'runtime/memory_web.dart'
    if (dart.library.io) 'runtime/memory_native.dart';
import 'responsiveness.dart' show distribution;

/// Holds batch size, model, dataset and update count fixed across policies.
Future<Map<String, Object?>> measureYieldFrequency(
    {String host = 'Dart CLI'}) async {
  final rows = <Map<String, Object?>>[];
  for (final family in ['CNN', 'GRU']) {
    String? reference;
    final recipe = AsyncDemoRecipe(family);
    final base = recipe.request(recipe.initial, 8).toJson();
    final inputs = base['inputs'] as List;
    final targets = base['targets'] as List;
    base['inputs'] = [for (var i = 0; i < 8; i++) ...inputs];
    base['targets'] = [for (var i = 0; i < 8; i++) ...targets];
    base['batchSize'] = 4;
    for (final policy in [
      (frequency: 1, chunk: 32, budget: null),
      (frequency: 4, chunk: 32, budget: null),
      (frequency: 16, chunk: 32, budget: null),
      (frequency: 16, chunk: 8, budget: null),
      (frequency: 16, chunk: 8, budget: 8000),
    ]) {
      final elapsed = <int>[], delays = <int>[], firstEvents = <int>[];
      for (var repeat = 0; repeat < 3; repeat++) {
        final data = Map<String, dynamic>.of(base)
          ..['batchesPerYield'] = policy.frequency
          ..['evaluationSamplesPerYield'] = policy.chunk
          ..['maxWorkMicroseconds'] = policy.budget;
        final request = AsyncTrainingRequest.fromJson(data);
        final clock = Stopwatch()..start();
        var last = 0;
        int? first;
        final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
          final now = clock.elapsedMicroseconds;
          delays.add(math.max(0, now - last - 1000));
          last = now;
        });
        final task = AsyncTrainingTask.start(request,
            execution: TrainingExecution.cooperative);
        final subscription = task.evaluationProgress
            .listen((_) => first ??= clock.elapsedMicroseconds);
        late AsyncTrainingResult result;
        try {
          result = await task.result;
        } finally {
          timer.cancel();
          await subscription.cancel();
          clock.stop();
        }
        elapsed.add(clock.elapsedMicroseconds);
        firstEvents.add(first!);
        final checkpoint = jsonEncode(result.checkpoint.toJson());
        reference ??= checkpoint;
        if (reference != checkpoint) {
          throw StateError('Yield policy changed $family weights/moments.');
        }
      }
      rows.add({
        'family': family,
        'samples': (base['inputs'] as List).length,
        'batchSize': 4,
        'epochs': 8,
        'batchesPerYield': policy.frequency,
        'evaluationSamplesPerYield': policy.chunk,
        'maxWorkMicroseconds': policy.budget,
        'repetitions': 3,
        'exactCheckpointMatch': true,
        'wall': distribution(elapsed),
        'eventLoopDelay': distribution(delays),
        'firstEvaluationEvent': distribution(firstEvents)
      });
    }
  }
  return {
    'host': host,
    ...runtimeInfo(),
    'seed': 42,
    'rows': rows,
    'notes':
        'Same batch size/data/order/math for every policy. Timers are event-loop proxies, not frame times; work budgets are checked between indivisible units.'
  };
}

Future<void> main() async {
  print('NEURAL_YIELD ${jsonEncode(await measureYieldFrequency())}');
}

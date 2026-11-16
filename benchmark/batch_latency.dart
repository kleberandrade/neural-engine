import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';

/// Times shared executor steps without adding instrumentation to the core API.
void main() {
  final inputs = List.generate(
      128, (i) => [i / 128, (i % 7) / 7, (i % 11) / 11, (i % 13) / 13]);
  final targets = inputs.map((x) => [x.reduce((a, b) => a + b) / 4]).toList();
  final reports = <Map<String, Object?>>[];
  for (final batch in [1, 8, 32]) {
    final model = NeuralNetwork(
        inputSize: 4,
        layers: [Dense(32, activation: Activation.tanh), Dense(1)],
        seed: 42);
    final iterator = MiniBatchTrainer<List<double>>()
        .steps(
            model: model,
            inputs: inputs,
            targets: targets,
            loss: const MeanSquaredError(),
            optimizer: Adam(learningRate: 0.01),
            epochs: 8,
            batchSize: batch,
            seed: 42)
        .iterator;
    final batchTimes = <int>[];
    int? firstStep, evaluation;
    while (true) {
      final watch = Stopwatch()..start();
      final more = iterator.moveNext();
      watch.stop();
      if (!more) break;
      if (iterator.current != null) {
        evaluation = watch.elapsedMicroseconds;
      } else if (firstStep == null) {
        firstStep = watch.elapsedMicroseconds;
      } else {
        batchTimes.add(watch.elapsedMicroseconds);
      }
    }
    batchTimes.sort();
    reports.add({
      'batchSize': batch,
      'samples': 128,
      'epochs': 8,
      'firstValidationAndBatchUs': firstStep,
      'finalEvaluationUs': evaluation,
      'remainingStepCount': batchTimes.length,
      'medianRemainingStepUs': batchTimes[batchTimes.length ~/ 2],
      'maxRemainingStepUs': batchTimes.last,
      'note':
          'Steps at later epoch boundaries also include training-loss evaluation. Upper bound for batch units, not isolated gradient-only timing.'
    });
  }
  print(jsonEncode({'kind': 'executor-step latency', 'results': reports}));
}

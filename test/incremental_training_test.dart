// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';
import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';
import '../example/flutter_lab/lib/runners/async_demo_recipe.dart';
import '../example/extensions/linear_model.dart';

String snapshot(TrainingCheckpoint c) => jsonEncode(c.toJson());
void main() {
  for (final family in ['MLP', 'CNN', 'RNN', 'LSTM', 'GRU', 'Autoencoder']) {
    for (final execution in [
      TrainingExecution.cooperative,
      TrainingExecution.isolate
    ]) {
      test(
          '$family $execution: chunks and yield frequency preserve complete state and loss',
          () async {
        final recipe = AsyncDemoRecipe(family);
        AsyncTrainingRequest request(
            int frequency, int chunk, Duration? budget) {
          final json = recipe.request(recipe.initial, 3).toJson();
          json['batchSize'] = 3;
          json['batchesPerYield'] = frequency;
          json['evaluationSamplesPerYield'] = chunk;
          json['maxWorkMicroseconds'] = budget?.inMicroseconds;
          return AsyncTrainingRequest.fromJson(json);
        }

        final reference = await AsyncTrainingTask.start(request(1, 1, null),
                execution: execution)
            .result;
        for (final frequency in [4, 16]) {
          final task = AsyncTrainingTask.start(
              request(frequency, 7, const Duration(milliseconds: 2)),
              execution: execution);
          final evaluations = <EvaluationProgress>[];
          final subscription = task.evaluationProgress.listen(evaluations.add);
          final result = await task.result;
          await subscription.cancel();
          expect(snapshot(result.checkpoint), snapshot(reference.checkpoint));
          expect(result.history.losses, reference.history.losses);
          expect(result.history.validationLosses,
              reference.history.validationLosses);
          expect(evaluations, isNotEmpty);
          for (final p in evaluations) {
            expect(p.incremental, isTrue);
            expect(p.samplesCompleted, inInclusiveRange(1, p.totalSamples));
            expect(p.loss == null, p.samplesCompleted != p.totalSamples);
          }
        }
      });
    }
  }
  test('fused sigmoid loss remains exact in saturated sample evaluation', () {
    final model = NeuralNetwork(
        inputSize: 1,
        layers: [Dense(1, activation: Activation.sigmoid)],
        seed: 42);
    model.parameters = [1000, 0];
    expect(
        model.sampleLoss(
            input: [1], target: [0], loss: const BinaryCrossEntropy()),
        1000);
    expect(
        model.evaluate(inputs: [
          [1]
        ], targets: [
          [0]
        ], loss: const BinaryCrossEntropy()),
        1000);
  });
  test(
      'evaluation chunks yield to timers during preflight; cancellation stays at epoch zero',
      () async {
    final data = List.generate(40, (i) => [i / 40]);
    final session = TrainingSession<List<double>>(
        model: NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42),
        optimizer: Adam(),
        seed: 42);
    final original = snapshot(session.checkpoint());
    final token = TrainingCancellation();
    var timerSeen = false, sawAfterTimer = false;
    final result = await session.fitAsync(
        inputs: data,
        targets: data,
        loss: const MeanSquaredError(),
        epochs: 10,
        evaluationSamplesPerYield: 4,
        batchesPerYield: 1000,
        cancellation: token,
        onEvaluationProgress: (p) {
          if (p.phase == TrainingPhase.trainingPreflight &&
              p.samplesCompleted == 4) {
            Timer.run(() => timerSeen = true);
            token.cancel();
          }
          if (p.samplesCompleted >= 8) sawAfterTimer = timerSeen;
        });
    expect(sawAfterTimer, isTrue);
    expect(result.cancelled, isTrue);
    expect(result.checkpoint.epochsCompleted, 0);
    expect(snapshot(result.checkpoint), original);
  });
  test(
      'invalid late sample is rejected before any update, even after cancellation',
      () async {
    final data = List.generate(40, (i) => i == 39 ? [1.0, 2.0] : [i / 40]);
    final model = NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42);
    final original = model.parameters;
    final session = TrainingSession<List<double>>(
        model: model, optimizer: Adam(), seed: 42);
    final token = TrainingCancellation();
    await expectLater(
        session.fitAsync(
            inputs: data,
            targets: List.generate(40, (_) => [0.0]),
            loss: const MeanSquaredError(),
            evaluationSamplesPerYield: 4,
            cancellation: token,
            onEvaluationProgress: (_) => token.cancel()),
        throwsArgumentError);
    expect(model.parameters, original);
    expect(session.checkpoint, throwsStateError);
  });
  test(
      'cancellation during final validation commits one full epoch with optimizer state',
      () async {
    final data = <List<double>>[
      [0],
      [0.25],
      [0.5],
      [0.75],
      [1]
    ];
    TrainingSession<List<double>> fresh() => TrainingSession(
        model: NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42),
        optimizer: Adam(),
        seed: 42);
    final reference = fresh();
    reference.fit(
        inputs: data,
        targets: data,
        loss: const MeanSquaredError(),
        epochs: 1,
        batchSize: 2);
    final token = TrainingCancellation();
    final result = await fresh().fitAsync(
        inputs: data,
        targets: data,
        validationInputs: data,
        validationTargets: data,
        loss: const MeanSquaredError(),
        epochs: 10,
        batchSize: 2,
        evaluationSamplesPerYield: 1,
        cancellation: token,
        onEvaluationProgress: (p) {
          if (p.phase == TrainingPhase.validationEvaluation &&
              p.samplesCompleted == 1) {
            token.cancel();
          }
        });
    expect(result.cancelled, isTrue);
    expect(result.checkpoint.epochsCompleted, 1);
    expect(snapshot(result.checkpoint), snapshot(reference.checkpoint()));
  });
  test('custom reduction stays atomic unless it opts into SampleLossModel',
      () async {
    final session = TrainingSession<List<double>>(
        model: LinearModel(), optimizer: SGD(), seed: 42);
    final events = <EvaluationProgress>[];
    await session.fitAsync(
        inputs: [
          [0],
          [1]
        ],
        targets: [
          [0],
          [1]
        ],
        loss: const MeanSquaredError(),
        epochs: 2,
        evaluationSamplesPerYield: 1,
        onEvaluationProgress: events.add);
    expect(events.every((p) => !p.incremental), isTrue);
    expect(events.every((p) => p.samplesCompleted == 2), isTrue);
  });
  test(
      'explicit work budget yields between batches even with a large batch-count threshold',
      () async {
    final model = _TimerProbe();
    final session =
        TrainingSession<List<double>>(model: model, optimizer: SGD(), seed: 42);
    await session.fitAsync(
        inputs: [
          [0],
          [0.25],
          [0.5],
          [1]
        ],
        targets: [
          [0],
          [0.25],
          [0.5],
          [1]
        ],
        loss: const MeanSquaredError(),
        epochs: 1,
        batchSize: 1,
        batchesPerYield: 100000,
        maxWorkDuration: const Duration(microseconds: 1));
    expect(model.observedBetweenBatches, isTrue);
  });
  test('invalid scheduling options reject before any update', () async {
    final recipe = AsyncDemoRecipe('MLP');
    for (final key in [
      'evaluationSamplesPerYield',
      'maxWorkMicroseconds',
      'batchesPerYield'
    ]) {
      final json = recipe.request(recipe.initial, 1).toJson();
      json[key] = 0;
      expect(() => AsyncTrainingRequest.fromJson(json), throwsArgumentError);
    }
  });
}

class _TimerProbe extends LinearModel {
  bool timerRan = false, observedBetweenBatches = false;
  int calls = 0;
  @override
  List<double> gradients(
      {required List<double> input,
      required List<double> target,
      required Loss loss}) {
    if (++calls == 1) Timer.run(() => timerRan = true);
    if (calls > 1 && timerRan) observedBetweenBatches = true;
    return super.gradients(input: input, target: target, loss: loss);
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';
// ignore: avoid_relative_lib_imports
import '../example/extensions/linear_model.dart';
// ignore: avoid_relative_lib_imports
import '../example/extensions/huber_loss.dart';
// ignore: avoid_relative_lib_imports
import '../example/extensions/momentum_optimizer.dart';

const vectors = <List<double>>[
  [0],
  [0.25],
  [0.5],
  [0.75],
  [1]
];
const targets = <List<double>>[
  [0],
  [0.25],
  [0.5],
  [0.75],
  [1]
];
TrainingSession<List<double>> fresh() => TrainingSession(
    model: NeuralNetwork(
        inputSize: 1,
        layers: [Dense(3, activation: Activation.tanh), Dense(1)],
        seed: 42),
    optimizer: Adam(learningRate: 0.02),
    seed: 42);
AsyncTrainingRequest request(TrainingCheckpoint checkpoint,
        {int epochs = 6, List<List<double>> inputs = vectors}) =>
    AsyncTrainingRequest(
        checkpoint: checkpoint,
        inputs: inputs,
        targets: targets,
        validationInputs: vectors,
        validationTargets: targets,
        loss: TrainingLoss.meanSquaredError,
        epochs: epochs,
        batchSize: 2);
void syncTrain(TrainingSession<List<double>> s, int epochs) => s.fit(
    inputs: vectors,
    targets: targets,
    loss: const MeanSquaredError(),
    epochs: epochs,
    batchSize: 2);
String snapshot(TrainingCheckpoint checkpoint) =>
    jsonEncode(checkpoint.toJson());

void main() {
  test('cooperative custom contracts preserve optimizer state exactly',
      () async {
    TrainingSession<List<double>> custom() => TrainingSession(
        model: LinearModel(), optimizer: MomentumOptimizer(), seed: 7);
    final sync = custom();
    final async = custom();
    final loss = HuberLoss();
    sync.fit(
        inputs: vectors, targets: targets, loss: loss, epochs: 8, batchSize: 2);
    final result = await async.fitAsync(
        inputs: vectors, targets: targets, loss: loss, epochs: 8, batchSize: 2);
    expect(snapshot(result.checkpoint), snapshot(sync.checkpoint()));
  });

  for (final execution in [
    TrainingExecution.cooperative,
    TrainingExecution.isolate
  ]) {
    test(
        '$execution exact continuation, progress, validation and immutable input',
        () async {
      final original = fresh();
      syncTrain(original, 3);
      final before = snapshot(original.checkpoint());
      final mutable = vectors.map(List<double>.of).toList();
      final jobRequest = request(original.checkpoint(), inputs: mutable);
      mutable[0][0] = 999;
      final job = AsyncTrainingTask.start(jobRequest, execution: execution);
      final events = <TrainingProgress>[];
      final done = Completer<void>();
      job.progress.listen(events.add, onDone: done.complete);
      final result = await job.result;
      await done.future;
      syncTrain(original, 6);
      expect(snapshot(result.checkpoint), snapshot(original.checkpoint()));
      expect(before, isNot(snapshot(original.checkpoint())));
      expect(result.history.epochs, 6);
      expect(result.cancelled, isFalse);
      expect(events.map((p) => p.epochsCompleted), [4, 5, 6, 7, 8, 9]);
      expect(events.last.fraction, 1);
      expect(events.map((p) => p.loss), result.history.losses);
      expect(
          events.map((p) => p.validationLoss), result.history.validationLosses);
      expect(events.last.elapsed, lessThanOrEqualTo(result.elapsed));
    });

    test('$execution pre-cancellation returns untouched resumable checkpoint',
        () async {
      final checkpoint = fresh().checkpoint();
      final job =
          AsyncTrainingTask.start(request(checkpoint), execution: execution)
            ..cancel();
      final result = await job.result;
      expect(result.cancelled, isTrue);
      expect(result.history.epochs, 0);
      expect(snapshot(result.checkpoint), snapshot(checkpoint));
    });

    test('$execution cancel from progress and resume equals uninterrupted',
        () async {
      final original = fresh();
      final job = AsyncTrainingTask.start(
          request(original.checkpoint(), epochs: 100),
          execution: execution);
      final subscription = job.progress.listen((p) {
        if (p.epochsThisRun >= 2) job.cancel();
      });
      final stopped = await job.result;
      await subscription.cancel();
      expect(stopped.cancelled, isTrue);
      expect(stopped.history.epochs, inInclusiveRange(2, 99));
      final remaining = 100 - stopped.checkpoint.epochsCompleted;
      final resumed = await AsyncTrainingTask.start(
              request(stopped.checkpoint, epochs: remaining),
              execution: execution)
          .result;
      syncTrain(original, 100);
      expect(snapshot(resumed.checkpoint), snapshot(original.checkpoint()));
    });

    test('$execution failed worker closes stream, leaves caller untouched',
        () async {
      final original = fresh();
      final before = snapshot(original.checkpoint());
      final job = AsyncTrainingTask.start(
          request(original.checkpoint(), inputs: const [
            [1, 2]
          ]),
          execution: execution);
      final streamDone = job.progress.drain<void>();
      await expectLater(
          job.result,
          throwsA(execution == TrainingExecution.isolate
              ? isA<TrainingWorkerException>()
              : isA<ArgumentError>()));
      await streamDone;
      expect(snapshot(original.checkpoint()), before);
    });

    for (final optimizer in ['adam', 'sgd']) {
      for (final family in ['MLP', 'CNN', 'RNN', 'LSTM', 'GRU']) {
        test('$execution $family $optimizer shares synchronous batch math',
            () async {
          Future<void> verify<I>(
              DifferentiableModel<I> Function() create,
              List<I> inputs,
              List<List<double>> targets,
              Loss loss,
              TrainingLoss wireLoss) async {
            TrainingSession<I> session() => TrainingSession(
                model: create(),
                seed: 42,
                optimizer: optimizer == 'adam'
                    ? Adam(learningRate: 0.01)
                    : SGD(learningRate: 0.01));
            final sync = session();
            final origin = session();
            sync.fit(
                inputs: inputs,
                targets: targets,
                loss: loss,
                epochs: 4,
                batchSize: 2,
                maxGradientNorm: 0.5);
            final result = await AsyncTrainingTask.start(
                    AsyncTrainingRequest(
                        checkpoint: origin.checkpoint(),
                        inputs: inputs.cast<Object>(),
                        targets: targets,
                        loss: wireLoss,
                        epochs: 4,
                        batchSize: 2,
                        maxGradientNorm: 0.5),
                    execution: execution)
                .result;
            expect(snapshot(result.checkpoint), snapshot(sync.checkpoint()));
            expect(origin.epochsCompleted, 0);
          }

          if (family == 'MLP') {
            await verify(
                () => NeuralNetwork(
                    inputSize: 1,
                    layers: [Dense(1, activation: Activation.sigmoid)],
                    seed: 42),
                vectors,
                targets,
                const BinaryCrossEntropy(),
                TrainingLoss.binaryCrossEntropy);
          } else if (family == 'CNN') {
            await verify(
                () => ConvolutionalNetwork(
                    inputHeight: 2,
                    inputWidth: 2,
                    seed: 42,
                    layers: [Conv2D(filters: 1, kernelSize: 1)],
                    denseLayers: [Dense(2, activation: Activation.softmax)]),
                [
                  ImageTensor(
                      height: 2, width: 2, channels: 1, values: [0, 1, 0, 1]),
                  ImageTensor(
                      height: 2, width: 2, channels: 1, values: [1, 1, 0, 0])
                ],
                [
                  [1, 0],
                  [0, 1]
                ],
                const CategoricalCrossEntropy(),
                TrainingLoss.categoricalCrossEntropy);
          } else {
            await verify(
                () => RecurrentNetwork(
                    inputSize: 1,
                    hiddenSize: 2,
                    outputSize: 1,
                    kind: RecurrentKind.values.byName(family.toLowerCase()),
                    seed: 42),
                [
                  [
                    [0.1],
                    [0.2]
                  ],
                  [
                    [0.3],
                    [0.4]
                  ],
                  [
                    [0.5],
                    [0.6]
                  ]
                ],
                [
                  [0.3],
                  [0.5],
                  [0.7]
                ],
                const MeanSquaredError(),
                TrainingLoss.meanSquaredError);
          }
        });
      }
    }
  }

  test(
      'cooperative yields inside an epoch and guards concurrent session access',
      () async {
    final session = fresh();
    final token = TrainingCancellation();
    final resultFuture = session.fitAsync(
        inputs: vectors,
        targets: targets,
        loss: const MeanSquaredError(),
        epochs: 10,
        batchSize: 1,
        cancellation: token);
    expect(() => syncTrain(session, 1), throwsStateError);
    expect(session.checkpoint, throwsStateError);
    await expectLater(
        session.fitAsync(
            inputs: vectors, targets: targets, loss: const MeanSquaredError()),
        throwsStateError);
    var heartbeats = 0;
    final timer = Timer.periodic(Duration.zero, (_) => heartbeats++);
    final result = await resultFuture;
    timer.cancel();
    expect(heartbeats, greaterThan(0));
    expect(result.checkpoint.epochsCompleted, 10);
    expect(session.checkpoint().epochsCompleted, 10);
  });

  test('cancellation received between batches commits the complete epoch',
      () async {
    final cancellation = TrainingCancellation();
    final model = _CancellationProbe(cancellation);
    final session = TrainingSession<List<double>>(
        model: model, optimizer: Adam(learningRate: 0.02), seed: 42);
    final result = await session.fitAsync(
        inputs: vectors,
        targets: targets,
        loss: const MeanSquaredError(),
        epochs: 10,
        batchSize: 1,
        cancellation: cancellation);
    expect(result.cancelled, isTrue);
    expect(result.history.epochs, 1);
    expect(model.gradientCalls, vectors.length);
    final reference = TrainingSession<List<double>>(
        model: LinearModel(), optimizer: Adam(learningRate: 0.02), seed: 42);
    reference.fit(
        inputs: vectors,
        targets: targets,
        loss: const MeanSquaredError(),
        epochs: 1,
        batchSize: 1);
    expect(snapshot(result.checkpoint), snapshot(reference.checkpoint()));
  });

  test('paused progress listener does not block result completion', () async {
    final job = AsyncTrainingTask.start(request(fresh().checkpoint()),
        execution: TrainingExecution.cooperative);
    final subscription = job.progress.listen((_) {})..pause();
    final result = await job.result.timeout(const Duration(seconds: 5));
    expect(result.history.epochs, 6);
    await subscription.cancel();
  });

  test('invalid async options reject without poisoning a healthy session',
      () async {
    final session = fresh();
    await expectLater(
        session.fitAsync(
            inputs: vectors,
            targets: targets,
            loss: const MeanSquaredError(),
            batchesPerYield: 0),
        throwsArgumentError);
    syncTrain(session, 1);
    expect(session.epochsCompleted, 1);
  });
}

class _CancellationProbe extends LinearModel {
  final TrainingCancellation cancellation;
  int gradientCalls = 0;
  _CancellationProbe(this.cancellation);
  @override
  List<double> gradients(
      {required List<double> input,
      required List<double> target,
      required Loss loss}) {
    if (++gradientCalls == 1) Timer.run(cancellation.cancel);
    return super.gradients(input: input, target: target, loss: loss);
  }
}

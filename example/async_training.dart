import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';

/// Runs unchanged on native Dart and compiled JavaScript/Node.
Future<void> main() async {
  final inputs = <List<double>>[
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1]
  ];
  final targets = <List<double>>[
    [0],
    [1],
    [1],
    [0]
  ];
  TrainingSession<List<double>> fresh() => TrainingSession(
      model: NeuralNetwork(inputSize: 2, seed: 42, layers: [
        Dense(8, activation: Activation.tanh),
        Dense(1, activation: Activation.sigmoid)
      ]),
      optimizer: Adam(learningRate: 0.02),
      seed: 42);
  AsyncTrainingRequest request(TrainingCheckpoint checkpoint, int epochs) =>
      AsyncTrainingRequest(
          checkpoint: checkpoint,
          inputs: inputs,
          targets: targets,
          validationInputs: inputs,
          validationTargets: targets,
          loss: TrainingLoss.binaryCrossEntropy,
          epochs: epochs,
          batchSize: 2,
          maxGradientNorm: 1);
  final reference = fresh();
  reference.fit(
      inputs: inputs,
      targets: targets,
      loss: const BinaryCrossEntropy(),
      epochs: 80,
      batchSize: 2,
      maxGradientNorm: 1);
  for (final execution in [
    TrainingExecution.automatic,
    TrainingExecution.cooperative
  ]) {
    final initial = fresh();
    final job = AsyncTrainingTask.start(request(initial.checkpoint(), 80),
        execution: execution);
    var events = 0;
    final subscription = job.progress.listen((p) {
      events++;
      if (p.epochsThisRun == 5) job.cancel();
    });
    final stopped = await job.result;
    await subscription.cancel();
    if (!stopped.cancelled || events < 5 || stopped.history.epochs >= 80) {
      throw StateError('Expected progress and safe mid-run cancellation.');
    }
    // JSON can be copied to disk by the application, then loaded in a new process.
    final checkpoint = TrainingCheckpoint.fromJson(
        jsonDecode(jsonEncode(stopped.checkpoint.toJson()))
            as Map<String, dynamic>);
    final resumed = await AsyncTrainingTask.start(
            request(checkpoint, 80 - checkpoint.epochsCompleted),
            execution: execution)
        .result;
    if (jsonEncode(resumed.checkpoint.toJson()) !=
        jsonEncode(reference.checkpoint().toJson())) {
      throw StateError(
          'Async continuation diverged from synchronous training.');
    }
    final model = NeuralNetwork.fromJson(resumed.checkpoint.model);
    print('${job.execution.name}: cancelled at ${checkpoint.epochsCompleted}, '
        'resumed to 80, exact replay; [0,1] -> ${model.predict([0, 1])}');
  }
  print('Async validation passed');
}

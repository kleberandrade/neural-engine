import 'dart:convert';
import 'dart:io';
import 'package:neural_engine/neural_engine.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Map<String, dynamic> roundTrip(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

Future<void> main() async {
  // This client must resolve the released artifact, never the checkout.
  final lock = File('pubspec.lock').readAsStringSync();
  require(
      lock.contains('url: "https://pub.dev"') &&
          lock.contains('source: hosted') &&
          lock.contains('version: "0.3.0"'),
      'Expected the exact hosted 0.3.0 dependency.');
  final packages =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, dynamic>;
  final entry = (packages['packages'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((p) => p['name'] == 'neural_engine');
  final root = entry['rootUri'] as String;
  require(root.contains('/hosted/') && root.endsWith('neural_engine-0.3.0'),
      'Expected a hosted 0.3.0 package root, never the source checkout.');
  final data = <List<double>>[
    [0],
    [0.25],
    [0.5],
    [0.75],
    [1]
  ];
  final targets = data.map((x) => <double>[2 * x.single + 1]).toList();
  NeuralNetwork fresh() => NeuralNetwork(
      inputSize: 1,
      layers: [Dense(3, activation: Activation.tanh), Dense(1)],
      seed: 42);
  TrainingSession<List<double>> session() => TrainingSession(
      model: fresh(), optimizer: Adam(learningRate: 0.02), seed: 42);
  void train(TrainingSession<List<double>> s, int epochs) => s.fit(
      inputs: data,
      targets: targets,
      loss: const MeanSquaredError(),
      epochs: epochs,
      batchSize: 3,
      maxGradientNorm: 1);
  final full = session();
  train(full, 10);
  final split = session();
  train(split, 4);
  // Persist to a real temporary file and restore into a new model/session.
  final directory = Directory.systemTemp.createTempSync('neural-hosted-');
  try {
    final file = File('${directory.path}/checkpoint.json')
      ..writeAsStringSync(jsonEncode(split.checkpoint().toJson()));
    final restored = TrainingSession<List<double>>.restore(
        checkpoint: TrainingCheckpoint.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>),
        modelDecoder: NeuralNetwork.fromJson);
    train(restored, 6);
    require(
        jsonEncode(full.checkpoint().toJson()) ==
            jsonEncode(restored.checkpoint().toJson()),
        'Checkpoint replay diverged.');
    final model = NeuralNetwork.fromJson(
        roundTrip((restored.model as NeuralNetwork).toJson()));
    require(
        jsonEncode(model.predict(data.first)) ==
            jsonEncode(restored.model.predict(data.first)),
        'Dense JSON changed inference.');
  } finally {
    directory.deleteSync(recursive: true);
  }
  final scaler = StandardScaler.fit(data);
  require(
      jsonEncode(StandardScaler.fromJson(roundTrip(scaler.toJson()))
              .transform(data.first)) ==
          jsonEncode(scaler.transform(data.first)),
      'Scaler changed inference.');
  final minMax = MinMaxScaler.fit(data);
  require(
      jsonEncode(MinMaxScaler.fromJson(roundTrip(minMax.toJson()))
              .transform(data.last)) ==
          jsonEncode(minMax.transform(data.last)),
      'MinMax scaler changed inference.');
  final som = SelfOrganizingMap(rows: 2, columns: 2, inputSize: 1, seed: 42)
    ..fit(data, epochs: 3);
  final somCopy = SelfOrganizingMap.fromJson(roundTrip(som.toJson()));
  require(
      somCopy.winner(data.first).distance == som.winner(data.first).distance,
      'SOM JSON changed inference.');
  final image =
      ImageTensor(height: 2, width: 2, channels: 1, values: [0, 1, 1, 0]);
  final cnn = ConvolutionalNetwork(
      inputHeight: 2,
      inputWidth: 2,
      seed: 42,
      layers: [Conv2D(filters: 1, kernelSize: 1)],
      denseLayers: [Dense(1)]);
  require(
      jsonEncode(ConvolutionalNetwork.fromJson(roundTrip(cnn.toJson()))
              .predict(image)) ==
          jsonEncode(cnn.predict(image)),
      'CNN JSON changed inference.');
  for (final kind in RecurrentKind.values) {
    final model = RecurrentNetwork(
        inputSize: 1, hiddenSize: 2, outputSize: 1, kind: kind, seed: 42);
    require(
        jsonEncode(RecurrentNetwork.fromJson(roundTrip(model.toJson()))
                .predict(data)) ==
            jsonEncode(model.predict(data)),
        '${kind.name} JSON changed inference.');
  }
  await verifyHostedAsync();
  print(
      'Hosted neural_engine 0.3.0: all families, fitted scalers, disk persistence and exact Adam continuation passed.');
}

Future<void> verifyHostedAsync() async {
  final vectors = <List<double>>[
    [0],
    [0.25],
    [0.5],
    [0.75],
    [1]
  ];
  final targets = vectors.map((x) => <double>[2 * x.single + 1]).toList();
  for (final adam in [true, false]) {
    for (final execution in [
      TrainingExecution.automatic,
      TrainingExecution.cooperative
    ]) {
      await _verifyAsync<List<double>>(
          create: () => NeuralNetwork(
              inputSize: 1,
              layers: [Dense(3, activation: Activation.tanh), Dense(1)],
              seed: 42),
          inputs: vectors,
          targets: targets,
          adam: adam,
          execution: execution);
      await _verifyAsync<ImageTensor>(
          create: () => ConvolutionalNetwork(
              inputHeight: 2,
              inputWidth: 2,
              seed: 42,
              layers: [Conv2D(filters: 1, kernelSize: 1)],
              denseLayers: [Dense(1)]),
          inputs: [
            ImageTensor(height: 2, width: 2, channels: 1, values: [0, 1, 0, 1]),
            ImageTensor(height: 2, width: 2, channels: 1, values: [1, 1, 0, 0])
          ],
          targets: [
            [0.25],
            [0.75]
          ],
          adam: adam,
          execution: execution);
      for (final kind in RecurrentKind.values) {
        await _verifyAsync<List<List<double>>>(
            create: () => RecurrentNetwork(
                inputSize: 1,
                hiddenSize: 2,
                outputSize: 1,
                kind: kind,
                seed: 42),
            inputs: [
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
            targets: [
              [0.3],
              [0.5],
              [0.7]
            ],
            adam: adam,
            execution: execution);
      }
    }
  }
  print(
      'Hosted 0.3.0 async: five families, Adam/SGD, automatic/cooperative, progress, cancellation, disk checkpoint and exact replay passed.');
}

Future<void> _verifyAsync<I>(
    {required DifferentiableModel<I> Function() create,
    required List<I> inputs,
    required List<List<double>> targets,
    required bool adam,
    required TrainingExecution execution}) async {
  TrainingSession<I> session() => TrainingSession(
      model: create(),
      seed: 42,
      optimizer: adam ? Adam(learningRate: 0.02) : SGD(learningRate: 0.02));
  final initial = session();
  void train(TrainingSession<I> s, int epochs) => s.fit(
      inputs: inputs,
      targets: targets,
      loss: const MeanSquaredError(),
      epochs: epochs,
      batchSize: 2,
      maxGradientNorm: 1);
  train(initial, 3);
  AsyncTrainingRequest request(TrainingCheckpoint checkpoint, int epochs) =>
      AsyncTrainingRequest(
          checkpoint: checkpoint,
          inputs: inputs.cast<Object>(),
          targets: targets,
          validationInputs: inputs.cast<Object>(),
          validationTargets: targets,
          loss: TrainingLoss.meanSquaredError,
          epochs: epochs,
          batchSize: 2,
          maxGradientNorm: 1);
  final unchanged = jsonEncode(initial.checkpoint().toJson());
  final task = AsyncTrainingTask.start(request(initial.checkpoint(), 100),
      execution: execution);
  final events = <TrainingProgress>[];
  final subscription = task.progress.listen((p) {
    events.add(p);
    if (p.epochsThisRun >= 2) task.cancel();
  });
  final stopped = await task.result;
  await subscription.cancel();
  require(stopped.cancelled && stopped.checkpoint.epochsCompleted >= 5,
      'Hosted cancellation failed.');
  require(jsonEncode(initial.checkpoint().toJson()) == unchanged,
      'Worker mutated the caller.');
  require(
      events.isNotEmpty &&
          events.every((p) => p.validationLoss?.isFinite ?? false),
      'Validation progress missing.');
  for (var i = 1; i < events.length; i++) {
    require(events[i].epochsCompleted == events[i - 1].epochsCompleted + 1,
        'Out-of-order progress.');
  }
  final directory = Directory.systemTemp.createTempSync('neural-030-async-');
  try {
    final file = File('${directory.path}/checkpoint.json')
      ..writeAsStringSync(jsonEncode(stopped.checkpoint.toJson()));
    final loaded = TrainingCheckpoint.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
    final resumed =
        await AsyncTrainingTask.start(request(loaded, 6), execution: execution)
            .result;
    final reference = session();
    train(reference, loaded.epochsCompleted + 6);
    require(
        jsonEncode(resumed.checkpoint.toJson()) ==
            jsonEncode(reference.checkpoint().toJson()),
        'Hosted async checkpoint replay diverged.');
  } finally {
    directory.deleteSync(recursive: true);
  }
}

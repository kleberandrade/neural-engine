import 'dart:convert';
import 'dart:io';
import 'package:neural_engine/neural_engine.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Map<String, dynamic> roundTrip(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  // This client must resolve the released artifact, never the checkout.
  final lock = File('pubspec.lock').readAsStringSync();
  require(
      lock.contains('url: "https://pub.dev"') &&
          lock.contains('source: hosted') &&
          lock.contains('version: "0.2.1"'),
      'Expected the exact hosted 0.2.1 dependency.');
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
  print(
      'Hosted neural_engine 0.2.1: all families, fitted scalers, disk persistence and exact Adam continuation passed.');
}

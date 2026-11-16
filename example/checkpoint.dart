import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';

void main() {
  final inputs = <List<double>>[
    [-1],
    [-0.5],
    [0],
    [0.5],
    [1]
  ];
  final targets = inputs.map((x) => <double>[2 * x.single + 1]).toList();
  final scaler = StandardScaler.fit(inputs);
  final restoredScaler = StandardScaler.fromJson(
      jsonDecode(jsonEncode(scaler.toJson())) as Map<String, dynamic>);
  final data = inputs.map(restoredScaler.transform).toList();
  NeuralNetwork model() =>
      NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42);
  final full = TrainingSession<List<double>>(
      model: model(), optimizer: Adam(learningRate: 0.03), seed: 42);
  final interrupted = TrainingSession<List<double>>(
      model: model(), optimizer: Adam(learningRate: 0.03), seed: 42);
  full.fit(
      inputs: data,
      targets: targets,
      loss: const MeanSquaredError(),
      epochs: 100,
      batchSize: 3);
  interrupted.fit(
      inputs: data,
      targets: targets,
      loss: const MeanSquaredError(),
      epochs: 40,
      batchSize: 3);
  final checkpoint = TrainingCheckpoint.fromJson(
      jsonDecode(jsonEncode(interrupted.checkpoint().toJson()))
          as Map<String, dynamic>);
  final resumed = TrainingSession<List<double>>.restore(
      checkpoint: checkpoint, modelDecoder: NeuralNetwork.fromJson);
  resumed.fit(
      inputs: data,
      targets: targets,
      loss: const MeanSquaredError(),
      epochs: 60,
      batchSize: 3);
  if (jsonEncode(full.checkpoint().toJson()) !=
      jsonEncode(resumed.checkpoint().toJson())) {
    throw StateError('Adam replay diverged.');
  }
  print(
      'Checkpoint replay: 100 epochs = 40 + restore + 60, including weights and Adam moments.');
  print(
      'Prediction for x=0.5: ${resumed.model.predict(restoredScaler.transform([
        0.5
      ]))}');
}

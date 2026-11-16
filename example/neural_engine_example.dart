import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';

void main() {
  final inputs = <List<double>>[
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1],
  ];
  final targets = <List<double>>[
    [0],
    [1],
    [1],
    [0],
  ];
  final network = NeuralNetwork(
    inputSize: 2,
    layers: [
      Dense(8, activation: Activation.tanh),
      Dense(1, activation: Activation.sigmoid),
    ],
    seed: 42,
  );
  final history = network.fit(
    inputs: inputs,
    targets: targets,
    loss: const BinaryCrossEntropy(),
    optimizer: Adam(learningRate: 0.03),
    epochs: 1200,
    batchSize: 4,
  );
  print('XOR loss: ${history.losses.last.toStringAsFixed(6)}');
  for (var i = 0; i < inputs.length; i++) {
    final prediction = network.predict(inputs[i]).single;
    print(
      '${inputs[i]} -> ${prediction.toStringAsFixed(4)} (target ${targets[i].single})',
    );
    if ((prediction - targets[i].single).abs() > 0.05) {
      throw StateError('XOR did not converge.');
    }
  }
  final encoded = jsonEncode(network.toJson());
  final restored = NeuralNetwork.fromJson(
    jsonDecode(encoded) as Map<String, dynamic>,
  );
  print('JSON roundtrip: ${restored.predict([0, 1])}');
}

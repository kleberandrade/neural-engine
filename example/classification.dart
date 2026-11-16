import 'package:neural_engine/neural_engine.dart';

void main() {
  final network = NeuralNetwork(
    inputSize: 2,
    layers: [Dense(3, activation: Activation.softmax)],
    seed: 42,
  );
  final inputs = <List<double>>[
    [-1, -1],
    [1, -1],
    [0, 1],
  ];
  final targets = <List<double>>[
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1],
  ];
  final history = network.fit(
    inputs: inputs,
    targets: targets,
    loss: const CategoricalCrossEntropy(),
    optimizer: Adam(learningRate: 0.05),
    epochs: 200,
    batchSize: 2,
  );
  for (var i = 0; i < inputs.length; i++) {
    final probabilities = network.predict(inputs[i]);
    print('Class $i: $probabilities');
    if (probabilities[i] < 0.98) {
      throw StateError('Classifier did not converge.');
    }
  }
  print('Final cross entropy: ${history.losses.last}');
}

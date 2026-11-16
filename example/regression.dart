import 'package:neural_engine/neural_engine.dart';

void main() {
  final network = NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42);
  final history = network.fit(
    inputs: [
      [-1],
      [0],
      [1],
    ],
    targets: [
      [-1],
      [1],
      [3],
    ],
    loss: const MeanSquaredError(),
    optimizer: SGD(learningRate: 0.1),
    epochs: 200,
    batchSize: 2,
  );
  final prediction = network.predict([0.5]).single;
  print('y = 2x + 1: x=0.5 -> $prediction; loss=${history.losses.last}');
  if ((prediction - 2).abs() > 1e-6) {
    throw StateError('Regression did not converge.');
  }
}

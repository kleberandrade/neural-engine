import 'package:neural_engine/neural_engine.dart';
import '../data/xor_dataset.dart';

Map<String, Object?> trainXor(Map<String, num> config) {
  final network = NeuralNetwork(inputSize: 2, seed: 42, layers: [
    Dense(config['units']!.toInt(), activation: Activation.tanh),
    Dense(1, activation: Activation.sigmoid),
  ]);
  final history = network.fit(
      inputs: xorInputs,
      targets: xorTargets,
      loss: const BinaryCrossEntropy(),
      optimizer: Adam(learningRate: config['rate']!.toDouble()),
      epochs: 800,
      batchSize: 4);
  return {'model': network.toJson(), 'losses': history.losses};
}

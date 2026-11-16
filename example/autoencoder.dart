import 'package:neural_engine/neural_engine.dart';
// Share pure Dart fixtures with the nested Flutter example, without Flutter imports.
// ignore: avoid_relative_lib_imports
import 'flutter_lab/lib/datasets.dart';

void main() {
  final train = reconstructionDataset();
  final test = reconstructionDataset(seed: 99);
  final model = NeuralNetwork(inputSize: 8, seed: 42, layers: [
    Dense(6, activation: Activation.tanh),
    Dense(2, activation: Activation.tanh),
    Dense(6, activation: Activation.tanh),
    Dense(8, activation: Activation.sigmoid),
  ]);
  final history = model.fit(
      inputs: train.inputs,
      targets: train.targets,
      loss: const BinaryCrossEntropy(),
      optimizer: Adam(learningRate: 0.02),
      epochs: 400,
      batchSize: 8);
  final mse = model.evaluate(
      inputs: test.inputs,
      targets: test.targets,
      loss: const MeanSquaredError());
  print(
      'Denoising autoencoder 8 -> 6 -> 2 -> 6 -> 8; training BCE=${history.losses.last}; test MSE=$mse');
  for (final pattern in reconstructionPatterns) {
    print(
        'Pattern $pattern -> latent=${model.layerOutputs(pattern)[1]} -> ${model.predict(pattern)}');
  }
  if (mse > 0.01) throw StateError('Autoencoder reconstruction failed.');
}

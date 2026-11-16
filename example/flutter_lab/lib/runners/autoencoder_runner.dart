import 'package:neural_engine/neural_engine.dart';
import '../datasets.dart';

Map<String, Object?> trainAutoencoder() {
  final train = reconstructionDataset();
  final test = reconstructionDataset(seed: 99);
  final model = NeuralNetwork(inputSize: 8, seed: 42, layers: [
    Dense(6, activation: Activation.tanh),
    Dense(2, activation: Activation.tanh),
    Dense(6, activation: Activation.tanh),
    Dense(8, activation: Activation.sigmoid)
  ]);
  final history = model.fit(
      inputs: train.inputs,
      targets: train.targets,
      loss: const BinaryCrossEntropy(),
      optimizer: Adam(learningRate: 0.02),
      epochs: 400,
      batchSize: 8);
  return {
    'curve': history.losses,
    'summary':
        'Held-out reconstruction MSE: ${model.evaluate(inputs: test.inputs, targets: test.targets, loss: const MeanSquaredError()).toStringAsFixed(6)}',
    'samples': [
      for (var i = 0; i < test.inputs.length; i += 5)
        <String, Object>{
          'input': test.inputs[i],
          'target': test.targets[i],
          'prediction': model.predict(test.inputs[i]),
          'latent': model.layerOutputs(test.inputs[i])[1],
        }
    ]
  };
}

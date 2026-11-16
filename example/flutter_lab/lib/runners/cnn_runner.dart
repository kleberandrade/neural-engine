import 'package:neural_engine/neural_engine.dart';
import '../datasets.dart';

Map<String, Object?> trainCnn() {
  final train = barDataset();
  final test = barDataset(seed: 99, repetitions: 1);
  final model = ConvolutionalNetwork(
      inputHeight: 6,
      inputWidth: 6,
      seed: 42,
      layers: [
        Conv2D(filters: 4, padding: ConvolutionPadding.same),
        MaxPool2D()
      ],
      denseLayers: [
        Dense(2, activation: Activation.softmax)
      ]);
  final history = model.fit(
      inputs: train.images,
      targets: train.targets,
      loss: const CategoricalCrossEntropy(),
      optimizer: Adam(learningRate: 0.02),
      epochs: 100,
      batchSize: 8);
  return {
    'model': model.toJson(),
    'curve': history.losses,
    'summary': 'Conv2D 6×6×4 → MaxPool 3×3×4 → Flatten 36 → Dense 2',
    'samples': [
      for (var i = 0; i < test.images.length; i++)
        <String, Object>{
          'input': test.images[i].values,
          'target': test.targets[i],
          'prediction': model.predict(test.images[i]),
          'features': model.featureMaps(test.images[i]).first.values,
        }
    ]
  };
}

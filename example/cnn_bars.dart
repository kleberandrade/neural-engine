import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
// Share pure Dart fixtures with the nested Flutter example, without Flutter imports.
// ignore: avoid_relative_lib_imports
import 'flutter_lab/lib/datasets.dart';

void main() {
  final train = barDataset();
  final test = barDataset(seed: 99, repetitions: 1);
  final model = ConvolutionalNetwork(
      inputHeight: 6,
      inputWidth: 6,
      layers: [
        Conv2D(filters: 4, kernelSize: 3, padding: ConvolutionPadding.same),
        MaxPool2D(),
      ],
      denseLayers: [Dense(2, activation: Activation.softmax)],
      seed: 42);
  final history = model.fit(
      inputs: train.images,
      targets: train.targets,
      loss: const CategoricalCrossEntropy(),
      optimizer: Adam(learningRate: 0.02),
      epochs: 100,
      batchSize: 8);
  var correct = 0;
  for (var i = 0; i < test.images.length; i++) {
    final p = model.predict(test.images[i]);
    final predicted = p[0] > p[1] ? 0 : 1;
    if (test.targets[i][predicted] == 1) correct++;
    print('Image $i -> ${predicted == 0 ? "vertical" : "horizontal"} $p');
  }
  print(
      'CNN loss=${history.losses.last}; held-out noise accuracy=$correct/${test.images.length}');
  print(
      'Feature maps: ${model.featureMaps(test.images.first).map((t) => "${t.height}x${t.width}x${t.channels}").join(" -> ")}');
  final restored = ConvolutionalNetwork.fromJson(
      jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>);
  if (correct != test.images.length ||
      restored.predict(test.images.first)[0] !=
          model.predict(test.images.first)[0]) {
    throw StateError('CNN convergence/roundtrip check failed.');
  }
}

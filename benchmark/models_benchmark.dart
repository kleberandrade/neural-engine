import 'dart:convert';
import 'dart:io';
import 'package:neural_engine/neural_engine.dart';
// Pure Dart fixtures used across example clients.
// ignore: avoid_relative_lib_imports
import '../example/flutter_lab/lib/datasets.dart';

Map<String, Object> measure<I>(String name, DifferentiableModel<I> model,
    List<I> inputs, List<List<double>> targets, Loss loss) {
  final trainer = MiniBatchTrainer<I>();
  final warm = Stopwatch()..start();
  trainer.fit(
      model: model,
      seed: 42,
      inputs: inputs,
      targets: targets,
      loss: loss,
      optimizer: Adam(learningRate: 0.01),
      epochs: 5,
      batchSize: 8,
      maxGradientNorm: 1);
  warm.stop();
  final training = Stopwatch()..start();
  trainer.fit(
      model: model,
      seed: 42,
      inputs: inputs,
      targets: targets,
      loss: loss,
      optimizer: Adam(learningRate: 0.01),
      epochs: 50,
      batchSize: 8,
      maxGradientNorm: 1);
  training.stop();
  for (var i = 0; i < 50; i++) {
    model.predict(inputs[i % inputs.length]);
  }
  final timings = <int>[];
  for (var repeat = 0; repeat < 5; repeat++) {
    final timer = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      model.predict(inputs[i % inputs.length]);
    }
    timer.stop();
    timings.add(timer.elapsedMicroseconds);
  }
  timings.sort();
  return {
    'model': name,
    'parameters': model.parameterCount,
    'samples': inputs.length,
    'epochs': 50,
    'warmupEpochs': 5,
    'trainingMicroseconds': training.elapsedMicroseconds,
    'medianPredictionMicroseconds': timings[2] / 1000
  };
}

void main() {
  final bars = barDataset();
  final sequence = sequenceDataset();
  final reconstruction = reconstructionDataset();
  final rows = <Map<String, Object>>[
    measure(
        'MLP XOR',
        NeuralNetwork(
            inputSize: 2,
            layers: [
              Dense(8, activation: Activation.tanh),
              Dense(1, activation: Activation.sigmoid)
            ],
            seed: 42),
        <List<double>>[
          [0, 0],
          [0, 1],
          [1, 0],
          [1, 1]
        ],
        <List<double>>[
          [0],
          [1],
          [1],
          [0]
        ],
        const BinaryCrossEntropy()),
    measure(
        'CNN bars',
        ConvolutionalNetwork(inputHeight: 6, inputWidth: 6, seed: 42, layers: [
          Conv2D(filters: 4, padding: ConvolutionPadding.same),
          MaxPool2D()
        ], denseLayers: [
          Dense(2, activation: Activation.softmax)
        ]),
        bars.images,
        bars.targets,
        const CategoricalCrossEntropy()),
    measure(
        'Dense autoencoder',
        NeuralNetwork(inputSize: 8, seed: 42, layers: [
          Dense(6, activation: Activation.tanh),
          Dense(2, activation: Activation.tanh),
          Dense(6, activation: Activation.tanh),
          Dense(8, activation: Activation.sigmoid)
        ]),
        reconstruction.inputs,
        reconstruction.targets,
        const BinaryCrossEntropy()),
    for (final kind in RecurrentKind.values)
      measure(
          kind.name,
          RecurrentNetwork(
              inputSize: 1, hiddenSize: 6, outputSize: 1, kind: kind, seed: 42),
          sequence.inputs,
          sequence.targets,
          const MeanSquaredError()),
  ];
  final som = SelfOrganizingMap(rows: 6, columns: 6, inputSize: 3, seed: 42);
  final colors = colorDataset();
  som.fit(colors, epochs: 5);
  final timer = Stopwatch()..start();
  som.fit(colors, epochs: 50);
  timer.stop();
  rows.add({
    'model': 'SOM colors',
    'parameters': 108,
    'samples': colors.length,
    'epochs': 50,
    'warmupEpochs': 5,
    'trainingMicroseconds': timer.elapsedMicroseconds
  });
  print(const JsonEncoder.withIndent('  ').convert({
    'runtime': Platform.version,
    'os': Platform.operatingSystem,
    'seed': 42,
    'notes':
        'Different workloads and parameter counts. One local run; no statistical speed ranking. Prediction median uses 5 batches of 1000 calls after warmup.',
    'results': rows
  }));
}

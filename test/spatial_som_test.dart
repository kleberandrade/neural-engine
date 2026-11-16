import 'dart:convert';
import 'dart:math' as math;
import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';
// Share pure Dart fixtures with the nested Flutter example, without Flutter imports.
// ignore: avoid_relative_lib_imports
import '../example/flutter_lab/lib/datasets.dart';

void main() {
  test('dense input gradient agrees with finite differences', () {
    final n = NeuralNetwork(inputSize: 2, seed: 7, layers: [
      Dense(3, activation: Activation.tanh),
      Dense(2, activation: Activation.softmax)
    ]);
    final input = <double>[0.3, -0.7];
    const loss = CategoricalCrossEntropy();
    final g = n.inputGradients(input: input, target: [0, 1], loss: loss);
    for (var i = 0; i < 2; i++) {
      final plus = List<double>.of(input)..[i] += 1e-5;
      final minus = List<double>.of(input)..[i] -= 1e-5;
      expect(
          g[i],
          closeTo(
              (n.evaluate(inputs: [
                        plus
                      ], targets: [
                        [0, 1]
                      ], loss: loss) -
                      n.evaluate(inputs: [
                        minus
                      ], targets: [
                        [0, 1]
                      ], loss: loss)) /
                  2e-5,
              1e-7));
    }
    expect(() => n.layerOutputs(input)[0][0] = 0, throwsUnsupportedError);
  });

  test('SOM BMU ties, Gaussian neighborhood and known update', () {
    final som = SelfOrganizingMap(rows: 1, columns: 2, inputSize: 1, seed: 7)
      ..weights = [
        [0],
        [1]
      ];
    expect(som.winner([0.5]).column, 0);
    som.fit([
      [0.25]
    ], epochs: 1, learningRate: 0.5, radius: 1, shuffle: false);
    expect(som.weights[0][0], closeTo(0.125, 1e-12));
    expect(som.weights[1][0], closeTo(1 - 0.375 * math.exp(-0.5), 1e-12));
    expect(() => som.weights[0][0] = 0, throwsUnsupportedError);
  });

  test('SOM learns colors reproducibly and preserves JSON', () {
    final data = colorDataset();
    final a = SelfOrganizingMap(rows: 6, columns: 6, inputSize: 3, seed: 42);
    final b = SelfOrganizingMap(rows: 6, columns: 6, inputSize: 3, seed: 42);
    final before = a.quantizationError(data);
    final history = a.fit(data, epochs: 80, radius: 3, finalRadius: 0.4);
    b.fit(data, epochs: 80, radius: 3, finalRadius: 0.4);
    expect(history.quantizationErrors.last, lessThan(before * 0.5));
    expect(a.weights, b.weights);
    final restored = SelfOrganizingMap.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
    expect(restored.weights, a.weights);
    expect(() => SelfOrganizingMap.fromJson({...a.toJson(), 'version': 2}),
        throwsFormatException);
    final snapshot = a.weights;
    expect(
        () => a.fit([
              [1, 2]
            ], epochs: 2),
        throwsArgumentError);
    expect(a.weights, snapshot);
    expect(() => a.fit(data, radius: 0), throwsArgumentError);
  });

  test('known cross-correlation and max pooling', () {
    final model = ConvolutionalNetwork(inputHeight: 3, inputWidth: 3, layers: [
      Conv2D(filters: 1, kernelSize: 2, activation: Activation.linear),
      MaxPool2D(),
    ], denseLayers: [
      Dense(1)
    ]);
    // Kernel top-left = 1, all other entries = 0, bias = 0; head identity.
    model.parameters = [1, 0, 0, 0, 0, 1, 0];
    final input = ImageTensor(
        height: 3, width: 3, channels: 1, values: [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    final maps = model.featureMaps(input);
    expect(maps[0].values, [1, 2, 4, 5]);
    expect(maps[1].values, [5]);
    expect(model.predict(input), [5]);
    final g = model.gradients(
        input: input, target: [0], loss: const MeanSquaredError());
    expect(g, [50, 60, 80, 90, 10, 50, 10]);
  });

  for (final padding in ConvolutionPadding.values) {
    test(
        'CNN all-parameter gradients: $padding, multiple channels, pooling and stacked kernels',
        () {
      final model = ConvolutionalNetwork(
          inputHeight: 5,
          inputWidth: 4,
          inputChannels: 2,
          seed: 7,
          layers: [
            Conv2D(
                filters: 2,
                kernelSize: 2,
                stride: padding == ConvolutionPadding.same ? 2 : 1,
                padding: padding,
                activation: Activation.tanh),
            MaxPool2D(poolSize: 2, stride: 1),
            Conv2D(filters: 2, kernelSize: 1, activation: Activation.tanh),
          ],
          denseLayers: [
            Dense(2, activation: Activation.softmax)
          ]);
      final input = ImageTensor(
          height: 5,
          width: 4,
          channels: 2,
          values:
              List.generate(40, (i) => math.sin(i * 0.71) * 0.4 + i * 0.003));
      final original = model.parameters;
      const loss = CategoricalCrossEntropy();
      final analytic =
          model.gradients(input: input, target: [0.2, 0.8], loss: loss);
      for (var p = 0; p < original.length; p++) {
        model.parameters = List<double>.of(original)..[p] += 1e-5;
        final high = model.evaluate(inputs: [
          input
        ], targets: [
          [0.2, 0.8]
        ], loss: loss);
        model.parameters = List<double>.of(original)..[p] -= 1e-5;
        final low = model.evaluate(inputs: [
          input
        ], targets: [
          [0.2, 0.8]
        ], loss: loss);
        expect(analytic[p], closeTo((high - low) / 2e-5, 2e-7),
            reason: 'parameter $p');
      }
    });
  }

  test('CNN learns noisy bars end-to-end and restores JSON', () {
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
    final before = model.parameters;
    final h = model.fit(
        inputs: train.images,
        targets: train.targets,
        loss: const CategoricalCrossEntropy(),
        optimizer: Adam(learningRate: 0.02),
        epochs: 100,
        batchSize: 7);
    expect(h.losses.last, lessThan(0.01));
    expect(model.parameters.take(40).toList(), isNot(before.take(40).toList()));
    for (var i = 0; i < test.images.length; i++) {
      expect(model.predict(test.images[i])[test.targets[i][0] == 1 ? 0 : 1],
          greaterThan(0.95));
    }
    final restored = ConvolutionalNetwork.fromJson(
        jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>);
    expect(
        restored.predict(test.images.first), model.predict(test.images.first));
    expect(
        () => ConvolutionalNetwork.fromJson({
              ...model.toJson(),
              'spatialParameters': [0]
            }),
        throwsFormatException);
  });

  test('spatial shapes, tensor bounds and boundary validation', () {
    expect(
        () =>
            ImageTensor(height: 1, width: 1, channels: 1, values: [double.nan]),
        throwsArgumentError);
    final tensor = ImageTensor(height: 1, width: 1, channels: 1, values: [1]);
    expect(() => tensor.at(0, 1, 0), throwsRangeError);
    expect(() => Conv2D(filters: 0), throwsArgumentError);
    expect(() => Conv2D(filters: 1, activation: Activation.softmax),
        throwsArgumentError);
    expect(
        () => ConvolutionalNetwork(
            inputHeight: 1,
            inputWidth: 1,
            layers: [Conv2D(filters: 1)],
            denseLayers: [Dense(1)]),
        throwsArgumentError);
    final n = ConvolutionalNetwork(
        inputHeight: 1,
        inputWidth: 1,
        layers: [Conv2D(filters: 1, kernelSize: 1)],
        denseLayers: [Dense(1)]);
    final before = n.parameters;
    expect(
        () => n.fit(inputs: [
              tensor
            ], targets: [
              [double.nan]
            ], loss: const MeanSquaredError(), optimizer: SGD()),
        throwsArgumentError);
    expect(n.parameters, before);
    expect(() => n.parameters = [0], throwsArgumentError);
  });

  test('denoising autoencoder reconstructs held-out noisy samples', () {
    final train = reconstructionDataset();
    final test = reconstructionDataset(seed: 99);
    final n = NeuralNetwork(inputSize: 8, seed: 42, layers: [
      Dense(6, activation: Activation.tanh),
      Dense(2, activation: Activation.tanh),
      Dense(6, activation: Activation.tanh),
      Dense(8, activation: Activation.sigmoid)
    ]);
    n.fit(
        inputs: train.inputs,
        targets: train.targets,
        loss: const BinaryCrossEntropy(),
        optimizer: Adam(learningRate: 0.02),
        epochs: 400,
        batchSize: 8);
    expect(
        n.evaluate(
            inputs: test.inputs,
            targets: test.targets,
            loss: const MeanSquaredError()),
        lessThan(0.01));
    expect(n.layerOutputs(test.inputs.first)[1], hasLength(2));
  });
}

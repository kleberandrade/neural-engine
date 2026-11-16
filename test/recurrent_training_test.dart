import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';

void main() {
  for (final kind in RecurrentKind.values) {
    test('$kind full BPTT matches every numerical parameter derivative', () {
      final n = RecurrentNetwork(
          inputSize: 2,
          hiddenSize: 2,
          outputSize: 2,
          kind: kind,
          outputActivation: Activation.softmax,
          seed: 7);
      final input = <List<double>>[
        [0.3, -0.2],
        [0.8, 0.1],
        [-0.1, 0.6]
      ];
      final weights = n.parameters;
      const loss = CategoricalCrossEntropy();
      final g = n.gradients(input: input, target: [0.2, 0.8], loss: loss);
      for (var p = 0; p < weights.length; p++) {
        n.parameters = List<double>.of(weights)..[p] += 1e-5;
        final high = n.evaluate(inputs: [
          input
        ], targets: [
          [0.2, 0.8]
        ], loss: loss);
        n.parameters = List<double>.of(weights)..[p] -= 1e-5;
        final low = n.evaluate(inputs: [
          input
        ], targets: [
          [0.2, 0.8]
        ], loss: loss);
        expect(g[p], closeTo((high - low) / 2e-5, 2e-7),
            reason: 'parameter $p');
      }
    });
    test('$kind state isolation, variable length and JSON roundtrip', () {
      final n = RecurrentNetwork(
          inputSize: 1, hiddenSize: 3, outputSize: 1, kind: kind, seed: 42);
      final a = <List<double>>[
        [0.1],
        [0.2]
      ];
      final before = n.predict(a);
      n.predict([
        [0.9]
      ]);
      expect(n.predict(a), before);
      final restored = RecurrentNetwork.fromJson(
          jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>);
      expect(restored.predict(a), before);
      expect(() => n.trace(a).first.hidden[0] = 0, throwsUnsupportedError);
      expect(() => n.predict([]), throwsArgumentError);
      expect(
          () => n.predict([
                [double.nan]
              ]),
          throwsArgumentError);
      expect(
          () => RecurrentNetwork.fromJson({...n.toJson(), 'kind': 'unknown'}),
          throwsFormatException);
    });
  }
  test(
      'CNN early stopping restores best validation epoch through shared trainer',
      () {
    final n = ConvolutionalNetwork(
        inputHeight: 1,
        inputWidth: 1,
        layers: [
          Conv2D(filters: 1, kernelSize: 1, activation: Activation.linear)
        ],
        denseLayers: [Dense(1)],
        seed: 7);
    final input = ImageTensor(height: 1, width: 1, channels: 1, values: [1]);
    n.parameters = [1, 0, 1, 0];
    final clone = ConvolutionalNetwork.fromJson(
        jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>);
    clone.fit(
        inputs: [
          input
        ],
        targets: [
          [0]
        ],
        loss: const MeanSquaredError(),
        optimizer: SGD(learningRate: 0.01),
        epochs: 1);
    final h = n.fit(
        inputs: [
          input
        ],
        targets: [
          [0]
        ],
        validationInputs: [
          input
        ],
        validationTargets: [
          [2]
        ],
        patience: 2,
        loss: const MeanSquaredError(),
        optimizer: SGD(learningRate: 0.01),
        epochs: 20);
    expect(h.stoppedEarly, isTrue);
    expect(h.bestEpoch, 1);
    expect(n.parameters, clone.parameters);
  });
  test('training-only scalers roundtrip, constants and no clipping', () {
    final standard = StandardScaler.fit([
      [1, 7],
      [3, 7]
    ]);
    expect(standard.means, [2, 7]);
    expect(standard.scales, [1, 1]);
    expect(standard.transform([3, 7]), [1, 0]);
    expect(standard.inverseTransform([1, 0]), [3, 7]);
    final minmax = MinMaxScaler.fit([
      [1, 7],
      [3, 7]
    ]);
    expect(minmax.transform([5, 7]), [2, 0]);
    expect(minmax.inverseTransform([2, 0]), [5, 7]);
    expect(
        () => StandardScaler.fit([
              [double.nan]
            ]),
        throwsArgumentError);
  });
  test('known classification and regression metrics', () {
    final m = ClassificationMetrics.fromLabels(
        targets: [0, 0, 1, 1], predictions: [0, 1, 1, 1], classCount: 2);
    expect(m.confusionMatrix, [
      [1, 1],
      [0, 2]
    ]);
    expect(m.accuracy, 0.75);
    expect(m.precision, [1, 2 / 3]);
    expect(m.recall, [0.5, 1]);
    final r = RegressionMetrics(targets: [1, 2, 3], predictions: [2, 2, 2]);
    expect(r.mse, 2 / 3);
    expect(r.mae, 2 / 3);
    expect(r.rSquared, 0);
    expect(RegressionMetrics(targets: [1, 1], predictions: [1, 1]).rSquared, 1);
  });
  test('SOM U-matrix and hit map have known grid distances/counts', () {
    final som = SelfOrganizingMap(rows: 2, columns: 2, inputSize: 1)
      ..weights = [
        [0],
        [2],
        [3],
        [7]
      ];
    expect(som.uMatrix(), [
      [2.5, 3.5],
      [3.5, 4.5]
    ]);
    expect(
        som.hitMap([
          [0],
          [0.1],
          [7]
        ]),
        [
          [2, 0],
          [0, 1]
        ]);
  });
  test('global norm clipping bounds a known update', () {
    final model = NeuralNetwork(inputSize: 1, layers: [Dense(1)])
      ..parameters = [0, 0];
    model.fit(
        inputs: [
          [1]
        ],
        targets: [
          [100]
        ],
        loss: const MeanSquaredError(),
        optimizer: SGD(learningRate: 1),
        epochs: 1,
        maxGradientNorm: 1);
    expect(model.parameters[0], closeTo(0.7071067811865475, 1e-12));
    expect(model.parameters[1], closeTo(0.7071067811865475, 1e-12));
  });
}

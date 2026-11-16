import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';

void main() {
  final x = <List<double>>[
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1],
  ];
  final y = <List<double>>[
    [0],
    [1],
    [1],
    [0],
  ];
  NeuralNetwork xor([int seed = 42]) => NeuralNetwork(
        inputSize: 2,
        layers: [
          Dense(8, activation: Activation.tanh),
          Dense(1, activation: Activation.sigmoid),
        ],
        seed: seed,
      );

  test('known forward pass, parameter ordering and defensive copies', () {
    final n = NeuralNetwork(inputSize: 2, layers: [Dense(1)]);
    final weights = <double>[2, 3, 1];
    n.parameters = weights;
    weights[0] = 999;
    expect(n.predict([4, 5]), [24]);
    expect(() => n.parameters[0] = 0, throwsUnsupportedError);
    expect(() => n.predict([4, 5])[0] = 0, throwsUnsupportedError);
    expect(() => n.parameters = [1], throwsArgumentError);
  });

  for (final activation in Activation.values) {
    for (final loss in <Loss>[
      const MeanSquaredError(),
      if (activation == Activation.sigmoid) const BinaryCrossEntropy(),
      if (activation == Activation.softmax) const CategoricalCrossEntropy(),
    ]) {
      test(
        'finite-difference gradients: $activation / ${loss.runtimeType}',
        () {
          // Includes hidden softmax Jacobian and multiple outputs.
          final n = NeuralNetwork(
            inputSize: 2,
            seed: 7,
            layers: [
              Dense(3, activation: activation),
              Dense(2, activation: activation),
            ],
          );
          final input = <double>[0.3, -0.7];
          final target = <double>[0.2, 0.8];
          final original = n.parameters;
          final analytic = n.gradients(
            input: input,
            target: target,
            loss: loss,
          );
          const h = 1e-5;
          for (var p = 0; p < original.length; p++) {
            final plus = List<double>.of(original)..[p] += h;
            final minus = List<double>.of(original)..[p] -= h;
            n.parameters = plus;
            final high = n.evaluate(
              inputs: [input],
              targets: [target],
              loss: loss,
            );
            n.parameters = minus;
            final low = n.evaluate(
              inputs: [input],
              targets: [target],
              loss: loss,
            );
            expect(
              analytic[p],
              closeTo((high - low) / (2 * h), 2e-7),
              reason: 'parameter $p',
            );
          }
        },
      );
    }
  }

  test('stable activations and cross entropy at extreme logits', () {
    expect(Activation.softmax.forward([1000, 1000]), [0.5, 0.5]);
    expect(Activation.sigmoid.forward([-1000, 1000]), [0, 1]);
    expect(Activation.tanh.forward([-1000, 1000]), [-1, 1]);
    final binary = NeuralNetwork(
      inputSize: 1,
      layers: [Dense(1, activation: Activation.sigmoid)],
    )..parameters = [0, -1000];
    expect(
      binary.evaluate(
        inputs: [
          [1],
        ],
        targets: [
          [1],
        ],
        loss: const BinaryCrossEntropy(),
      ),
      1000,
    );
    expect(
      binary.gradients(
        input: [1],
        target: [1],
        loss: const BinaryCrossEntropy(),
      ),
      [-1, -1],
    );
    final categorical = NeuralNetwork(
      inputSize: 1,
      layers: [Dense(2, activation: Activation.softmax)],
    )..parameters = [0, 1000, 0, -1000];
    expect(
      categorical.evaluate(
        inputs: [
          [1],
        ],
        targets: [
          [0, 1],
        ],
        loss: const CategoricalCrossEntropy(),
      ),
      2000,
    );
    expect(
      categorical.gradients(
        input: [1],
        target: [0, 1],
        loss: const CategoricalCrossEntropy(),
      ),
      [1, 1, -1, -1],
    );
  });

  test('SGD and Adam have known first updates', () {
    final p = <double>[1, -1];
    SGD(learningRate: 0.1).createState(2).update(p, [2, -4]);
    expect(p, [0.8, -0.6]);
    final q = <double>[1, -1];
    Adam(learningRate: 0.1).createState(2).update(q, [2, -4]);
    expect(q[0], closeTo(0.9, 1e-8));
    expect(q[1], closeTo(-0.9, 1e-8));
  });

  for (final seed in [7, 42, 123]) {
    test('XOR converges with seed $seed', () {
      final n = xor(seed);
      final history = n.fit(
        inputs: x,
        targets: y,
        loss: const BinaryCrossEntropy(),
        optimizer: Adam(learningRate: 0.03),
        epochs: 1200,
        batchSize: 4,
      );
      expect(history.losses.last, lessThan(0.02));
      for (var i = 0; i < x.length; i++) {
        expect(n.predict(x[i]).single, closeTo(y[i].single, 0.05));
      }
    });
  }

  test('seed reproducibility and optimizer configuration can be shared', () {
    final a = xor();
    final b = xor();
    final optimizer = Adam(learningRate: 0.02);
    final ha = a.fit(
      inputs: x,
      targets: y,
      loss: const BinaryCrossEntropy(),
      optimizer: optimizer,
      epochs: 20,
      batchSize: 3,
    );
    final hb = b.fit(
      inputs: x,
      targets: y,
      loss: const BinaryCrossEntropy(),
      optimizer: optimizer,
      epochs: 20,
      batchSize: 3,
    );
    expect(a.parameters, b.parameters);
    expect(ha.losses, hb.losses);
  });

  test('SGD regression and partial final mini-batch', () {
    final n = NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42);
    n.fit(
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
    expect(n.predict([0.5]).single, closeTo(2, 1e-6));
  });

  test('multiclass softmax learns three classes', () {
    final n = NeuralNetwork(
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
    n.fit(
      inputs: inputs,
      targets: targets,
      loss: const CategoricalCrossEntropy(),
      optimizer: Adam(learningRate: 0.05),
      epochs: 200,
      batchSize: 2,
    );
    for (var i = 0; i < 3; i++) {
      expect(n.predict(inputs[i])[i], greaterThan(0.98));
    }
  });

  test('early stopping restores best validation weights', () {
    final n = NeuralNetwork(inputSize: 1, layers: [Dense(1)])
      ..parameters = [0, 0];
    final h = n.fit(
      inputs: [
        [1],
      ],
      targets: [
        [1],
      ],
      validationInputs: [
        [1],
      ],
      validationTargets: [
        [-1],
      ],
      patience: 2,
      loss: const MeanSquaredError(),
      optimizer: SGD(learningRate: 0.1),
      epochs: 20,
    );
    expect(h.epochs, 3);
    expect(h.bestEpoch, 1);
    expect(h.stoppedEarly, isTrue);
    expect(n.predict([1]).single, closeTo(0.4, 1e-12));
    expect(() => h.losses.add(0), throwsUnsupportedError);
  });

  test('JSON roundtrip preserves predictions and rejects corrupt models', () {
    final n = xor();
    final loaded = NeuralNetwork.fromJson(
      jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>,
    );
    expect(loaded.predictBatch(x), n.predictBatch(x));
    expect(loaded.parameters, n.parameters);
    expect(
      () => NeuralNetwork.fromJson({...n.toJson(), 'version': 2}),
      throwsFormatException,
    );
    expect(
      () => NeuralNetwork.fromJson({
        ...n.toJson(),
        'parameters': [0],
      }),
      throwsFormatException,
    );
    expect(
      () => NeuralNetwork.fromJson({
        ...n.toJson(),
        'parameters': List.filled(n.parameterCount, double.nan),
      }),
      throwsFormatException,
    );
    expect(
      () => NeuralNetwork.fromJson({
        ...n.toJson(),
        'layers': [
          {'units': 1, 'activation': 'unknown'},
        ],
      }),
      throwsFormatException,
    );
    expect(() => NeuralNetwork.fromJson({}), throwsFormatException);
  });

  test(
    'invalid data and configurations fail before training mutates weights',
    () {
      final n = xor();
      final original = n.parameters;
      expect(() => n.predict([double.nan, 0]), throwsArgumentError);
      expect(() => n.predict([0]), throwsArgumentError);
      expect(
        () => n.fit(
          inputs: x,
          targets: [
            [0],
            [1],
            [1],
            [2],
          ],
          loss: const BinaryCrossEntropy(),
          optimizer: SGD(),
        ),
        throwsArgumentError,
      );
      expect(n.parameters, original);
      expect(
        () => n.fit(
          inputs: x,
          targets: y,
          loss: const BinaryCrossEntropy(),
          optimizer: SGD(),
          patience: 2,
        ),
        throwsArgumentError,
      );
      expect(
        () => n.fit(
          inputs: x,
          targets: y,
          loss: const BinaryCrossEntropy(),
          optimizer: SGD(),
          batchSize: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            n.evaluate(inputs: [], targets: [], loss: const MeanSquaredError()),
        throwsArgumentError,
      );
      expect(
        () => NeuralNetwork(inputSize: 0, layers: [Dense(1)]),
        throwsArgumentError,
      );
      expect(() => Dense(0), throwsArgumentError);
      expect(() => Adam(beta1: 1), throwsArgumentError);
      expect(() => SGD(learningRate: double.nan), throwsArgumentError);
      final linear = NeuralNetwork(inputSize: 1, layers: [Dense(1)]);
      expect(
        () => linear.evaluate(
          inputs: [
            [1],
          ],
          targets: [
            [1],
          ],
          loss: const BinaryCrossEntropy(),
        ),
        throwsArgumentError,
      );
      expect(
        () => const CategoricalCrossEntropy().value([0.2, 0.8], [1, 1]),
        throwsArgumentError,
      );
    },
  );
}

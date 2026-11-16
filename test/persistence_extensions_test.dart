import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';
import '../example/extensions/huber_loss.dart';
import '../example/extensions/linear_model.dart';

Map<String, dynamic> decode(Map<String, Object?> data) =>
    jsonDecode(jsonEncode(data)) as Map<String, dynamic>;

void replay<I>(
    String name,
    DifferentiableModel<I> Function() build,
    DifferentiableModel<I> Function(Map<String, dynamic>) decoder,
    List<I> inputs,
    List<List<double>> targets) {
  for (final adam in [true, false]) {
    test(
        '$name ${adam ? 'Adam' : 'SGD'} exact split-session replay with partial shuffled batches',
        () {
      CheckpointOptimizer optimizer() =>
          adam ? Adam(learningRate: 0.02) : SGD(learningRate: 0.02);
      final full =
          TrainingSession<I>(model: build(), optimizer: optimizer(), seed: 123);
      final split =
          TrainingSession<I>(model: build(), optimizer: optimizer(), seed: 123);
      full.fit(
          inputs: inputs,
          targets: targets,
          loss: const MeanSquaredError(),
          epochs: 9,
          batchSize: 2,
          maxGradientNorm: 0.5);
      split.fit(
          inputs: inputs,
          targets: targets,
          loss: const MeanSquaredError(),
          epochs: 4,
          batchSize: 2,
          maxGradientNorm: 0.5);
      final checkpoint =
          TrainingCheckpoint.fromJson(decode(split.checkpoint().toJson()));
      final resumed = TrainingSession<I>.restore(
          checkpoint: checkpoint, modelDecoder: decoder);
      resumed.fit(
          inputs: inputs,
          targets: targets,
          loss: const MeanSquaredError(),
          epochs: 5,
          batchSize: 2,
          maxGradientNorm: 0.5);
      expect(resumed.epochsCompleted, 9);
      expect(resumed.model.parameters, full.model.parameters);
      expect(resumed.checkpoint().toJson(), full.checkpoint().toJson());
    });
  }
}

void main() {
  replay<List<double>>(
      'Dense',
      () => NeuralNetwork(
          inputSize: 1,
          layers: [Dense(2, activation: Activation.tanh), Dense(1)],
          seed: 7),
      NeuralNetwork.fromJson,
      [
        [-1],
        [-0.5],
        [0],
        [0.5],
        [1]
      ],
      [
        [-1],
        [0],
        [1],
        [2],
        [3]
      ]);
  final images = [
    for (final v in [-1.0, 0.0, 1.0])
      ImageTensor(height: 1, width: 1, channels: 1, values: [v])
  ];
  replay<ImageTensor>(
      'CNN',
      () => ConvolutionalNetwork(
              inputHeight: 1,
              inputWidth: 1,
              seed: 7,
              layers: [
                Conv2D(filters: 2, kernelSize: 1, activation: Activation.tanh)
              ],
              denseLayers: [
                Dense(1)
              ]),
      ConvolutionalNetwork.fromJson,
      images,
      [
        [-1],
        [0],
        [1]
      ]);
  for (final kind in RecurrentKind.values) {
    replay<List<List<double>>>(
        kind.name,
        () => RecurrentNetwork(
            inputSize: 1, hiddenSize: 2, outputSize: 1, kind: kind, seed: 7),
        RecurrentNetwork.fromJson,
        [
          [
            [0.1]
          ],
          [
            [0.2],
            [0.3]
          ],
          [
            [0.5],
            [0.2],
            [0.1]
          ]
        ],
        [
          [0.1],
          [0.5],
          [0.8]
        ]);
  }
  test(
      'scaler JSON preserves fitted statistics, inverse transforms and constants',
      () {
    final standard = StandardScaler.fit([
      [1, 7],
      [3, 7]
    ]);
    final minmax = MinMaxScaler.fit([
      [1, 7],
      [3, 7]
    ]);
    final a = StandardScaler.fromJson(decode(standard.toJson()));
    final b = MinMaxScaler.fromJson(decode(minmax.toJson()));
    expect(a.transform([5, 7]), standard.transform([5, 7]));
    expect(b.transform([5, 7]), [2, 0]);
    expect(a.inverseTransform(a.transform([5, 7])), [5, 7]);
    expect(b.inverseTransform(b.transform([5, 7])), [5, 7]);
    final payload = standard.toJson();
    (payload['means']! as List<double>)[0] = 999;
    expect(standard.means, [2, 7]);
    for (final corrupt in <Map<String, dynamic>>[
      {...a.toJson(), 'version': 2},
      {...a.toJson(), 'means': <double>[]},
      {
        ...a.toJson(),
        'scales': [0, 1]
      },
      {
        ...a.toJson(),
        'scales': [1]
      },
      {
        ...a.toJson(),
        'means': [double.nan, 7]
      },
      {
        ...a.toJson(),
        'scales': [-1, 1]
      },
    ]) {
      expect(() => StandardScaler.fromJson(corrupt), throwsFormatException);
    }
    expect(
        () => MinMaxScaler.fromJson({
              ...b.toJson(),
              'ranges': [0, 1]
            }),
        throwsFormatException);
  });
  test('checkpoint snapshots are deep copies, progress/version are validated',
      () {
    final session = TrainingSession<List<double>>(
        model: LinearModel(), optimizer: Adam(), seed: 7);
    final checkpoint = session.checkpoint();
    final copy = checkpoint.model;
    (copy['parameters'] as List<dynamic>)[0] = 999;
    expect(session.model.parameters, [0, 0]);
    expect(checkpoint.model['parameters'], [0, 0]);
    expect(
        () =>
            TrainingCheckpoint.fromJson({...checkpoint.toJson(), 'version': 2}),
        throwsFormatException);
    expect(
        () => TrainingCheckpoint.fromJson(
            {...checkpoint.toJson(), 'epochsCompleted': -1}),
        throwsFormatException);
    expect(
        () => TrainingCheckpoint.fromJson({...checkpoint.toJson(), 'seed': -1}),
        throwsFormatException);
  });
  test('optimizer state codecs reject incompatible moments and dimensions', () {
    final adam = Adam();
    final state = adam.createState(2) as CheckpointOptimizerState;
    final json = decode(state.toJson());
    for (final invalid in <Map<String, dynamic>>[
      {...json, 'version': 2},
      {...json, 'step': -1},
      {
        ...json,
        'firstMoment': [0]
      },
      {
        ...json,
        'secondMoment': [-1, 0]
      },
      {
        ...json,
        'firstMoment': [double.nan, 0]
      },
      {
        ...json,
        'firstMoment': [1, 0]
      },
    ]) {
      expect(() => adam.restoreState(invalid, 2), throwsFormatException);
    }
    expect(
        () => SGD().restoreState({
              'format': 'neural_engine_sgd_state',
              'version': 1,
              'parameterCount': 3
            }, 2),
        throwsFormatException);
    expect(() => OptimizerCodec.decode({'format': 'unknown', 'version': 1}),
        throwsFormatException);
  });
  test('external Huber loss has correct gradient on dense network', () {
    final loss = HuberLoss();
    expect(loss.value([2], [0]), 1.5);
    expect(loss.gradient([2], [0]), [1]);
    final model = NeuralNetwork(inputSize: 1, layers: [Dense(1)])
      ..parameters = [0.1, 0.2];
    final weights = model.parameters;
    final analytic = model.gradients(input: [0.7], target: [0.8], loss: loss);
    for (var p = 0; p < weights.length; p++) {
      model.parameters = List<double>.of(weights)..[p] += 1e-5;
      final high = model.evaluate(inputs: [
        [0.7]
      ], targets: [
        [0.8]
      ], loss: loss);
      model.parameters = List<double>.of(weights)..[p] -= 1e-5;
      final low = model.evaluate(inputs: [
        [0.7]
      ], targets: [
        [0.8]
      ], loss: loss);
      expect(analytic[p], closeTo((high - low) / 2e-5, 1e-8));
    }
  });
  test(
      'custom model/optimizer boundary failures do not commit candidate weights',
      () {
    final model = LinearModel();
    expect(
        () => MiniBatchTrainer<List<double>>().fit(
            model: model,
            inputs: [
              [1]
            ],
            targets: [
              [1]
            ],
            loss: const MeanSquaredError(),
            optimizer: _InvalidOptimizer(),
            epochs: 1),
        throwsStateError);
    expect(model.parameters, [0, 0]);
    expect(
        () => MiniBatchTrainer<List<double>>().fit(
            model: _InvalidGradientModel(),
            inputs: [
              [1]
            ],
            targets: [
              [1]
            ],
            loss: const MeanSquaredError(),
            optimizer: SGD(),
            epochs: 1),
        throwsStateError);
    expect(
        () => MiniBatchTrainer<List<double>>().fit(
            model: _InvalidEvaluationModel(),
            inputs: [
              [1]
            ],
            targets: [
              [1]
            ],
            loss: const MeanSquaredError(),
            optimizer: SGD(),
            epochs: 1),
        throwsStateError);
  });
  test('failed sessions refuse further fits and checkpoints', () {
    final session = TrainingSession<List<double>>(
        model: LinearModel(), optimizer: Adam(), seed: 7);
    expect(
        () => session.fit(inputs: [
              [1]
            ], targets: [
              [1]
            ], loss: const MeanSquaredError(), epochs: 0),
        throwsArgumentError);
    expect(() => session.checkpoint(), throwsStateError);
    expect(
        () => session.fit(inputs: [
              [1]
            ], targets: [
              [1]
            ], loss: const MeanSquaredError()),
        throwsStateError);
  });
}

class _InvalidOptimizer implements Optimizer {
  @override
  OptimizerState createState(int parameterCount) => _InvalidState();
}

class _InvalidState implements OptimizerState {
  @override
  void update(List<double> parameters, List<double> gradients) =>
      parameters.add(0);
}

class _InvalidGradientModel extends LinearModel {
  @override
  List<double> gradients(
          {required List<double> input,
          required List<double> target,
          required Loss loss}) =>
      [1];
}

class _InvalidEvaluationModel extends LinearModel {
  @override
  double evaluate(
          {required List<List<double>> inputs,
          required List<List<double>> targets,
          required Loss loss}) =>
      double.nan;
}

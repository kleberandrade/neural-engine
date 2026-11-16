import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import '../data/xor_dataset.dart';
import '../data/bar_dataset.dart';
import '../data/sequence_dataset.dart';

/// Isolate entry point. The editable JSON is the only state crossing requests.
Map<String, Object> runCheckpointDemo(Map<String, Object> request) {
  final family = request['family']! as String;
  final action = request['action']! as String;
  if (!['MLP', 'CNN', 'RNN', 'LSTM', 'GRU'].contains(family)) {
    throw ArgumentError('Unknown checkpoint family.');
  }
  if (family == 'MLP') {
    return _run<List<double>>(
        request,
        xorInputs,
        xorTargets,
        const BinaryCrossEntropy(),
        () => NeuralNetwork(inputSize: 2, seed: 42, layers: [
              Dense(8, activation: Activation.tanh),
              Dense(1, activation: Activation.sigmoid)
            ]),
        NeuralNetwork.fromJson,
        action);
  }
  if (family == 'CNN') {
    final data = barDataset();
    return _run<ImageTensor>(
        request,
        data.images,
        data.targets,
        const CategoricalCrossEntropy(),
        () => ConvolutionalNetwork(
                inputHeight: 6,
                inputWidth: 6,
                seed: 42,
                layers: [
                  Conv2D(filters: 2, padding: ConvolutionPadding.same),
                  MaxPool2D()
                ],
                denseLayers: [
                  Dense(2, activation: Activation.softmax)
                ]),
        ConvolutionalNetwork.fromJson,
        action);
  }
  final data = sequenceDataset();
  final kind = RecurrentKind.values.byName(family.toLowerCase());
  return _run<List<List<double>>>(
      request,
      data.inputs,
      data.targets,
      const MeanSquaredError(),
      () => RecurrentNetwork(
          inputSize: 1, hiddenSize: 4, outputSize: 1, kind: kind, seed: 42),
      RecurrentNetwork.fromJson,
      action);
}

Map<String, Object> _run<I>(
    Map<String, Object> request,
    List<I> inputs,
    List<List<double>> targets,
    Loss loss,
    DifferentiableModel<I> Function() create,
    DifferentiableModel<I> Function(Map<String, dynamic>) decode,
    String action) {
  TrainingSession<I> fresh() => TrainingSession<I>(
      model: create(), optimizer: Adam(learningRate: 0.02), seed: 42);
  void train(TrainingSession<I> session, int epochs) => session.fit(
      inputs: inputs,
      targets: targets,
      loss: loss,
      epochs: epochs,
      batchSize: 3,
      maxGradientNorm: 1);
  late TrainingSession<I> session;
  if (action == 'start') {
    session = fresh();
    train(session, 40);
  } else if (action == 'load' || action == 'resume') {
    final envelope =
        jsonDecode(request['json']! as String) as Map<String, dynamic>;
    if (envelope['format'] != 'neural-engine-lab' ||
        envelope['version'] != 1 ||
        envelope['family'] != request['family']) {
      throw const FormatException(
          'Select the family saved in this lab checkpoint.');
    }
    final checkpoint = TrainingCheckpoint.fromJson(
        envelope['checkpoint'] as Map<String, dynamic>);
    session = TrainingSession<I>.restore(
        checkpoint: checkpoint, modelDecoder: decode);
    // Only this lab's fixed data, model and training recipe are accepted.
    final expected = fresh();
    if (session.seed != 42 ||
        jsonEncode(session.optimizer.toJson()) !=
            jsonEncode(expected.optimizer.toJson()) ||
        session.model.parameterCount != expected.model.parameterCount ||
        ![40, 100].contains(session.epochsCompleted)) {
      throw const FormatException(
          'Expected this demo configuration at epoch 40 or 100.');
    }
    // Validate input/output shape before accepting any state in the UI.
    for (var i = 0; i < inputs.length; i++) {
      loss.value(session.model.predict(inputs[i]), targets[i]);
    }
    if (action == 'resume') {
      if (session.epochsCompleted != 40) {
        throw const FormatException(
            'Resume requires a checkpoint at epoch 40.');
      }
      train(session, 60);
    }
  } else {
    throw ArgumentError('Unknown checkpoint action.');
  }
  final reference = fresh();
  train(reference, session.epochsCompleted);
  final predictions = inputs.map(session.model.predict).toList();
  final baseline = inputs.map(reference.model.predict).toList();
  var maxDifference = 0.0;
  var totalLoss = 0.0;
  for (var i = 0; i < predictions.length; i++) {
    totalLoss += loss.value(predictions[i], targets[i]) / inputs.length;
    for (var j = 0; j < predictions[i].length; j++) {
      final difference = (predictions[i][j] - baseline[i][j]).abs();
      if (difference > maxDifference) maxDifference = difference;
    }
  }
  final json = const JsonEncoder.withIndent('  ').convert({
    'format': 'neural-engine-lab',
    'version': 1,
    'family': request['family'],
    'checkpoint': session.checkpoint().toJson()
  });
  return {
    'json': json,
    'epochs': session.epochsCompleted,
    'loss': totalLoss,
    'bytes': utf8.encode(json).length,
    'maxDifference': maxDifference,
    'exact': jsonEncode(session.checkpoint().toJson()) ==
        jsonEncode(reference.checkpoint().toJson()),
    'predictions': predictions.take(4).toList(),
    'reference': baseline.take(4).toList(),
    'targets': targets.take(4).toList()
  };
}

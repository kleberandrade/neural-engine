import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import 'huber_loss.dart';
import 'momentum_optimizer.dart';
import 'linear_model.dart';

void main() {
  final inputs = <List<double>>[
    [-1],
    [-0.5],
    [0],
    [0.5],
    [1]
  ];
  final targets = inputs.map((x) => <double>[3 * x.single + 2]).toList();
  final model = LinearModel();
  final loss = HuberLoss();
  MiniBatchTrainer<List<double>>().fit(
      model: model,
      inputs: inputs,
      targets: targets,
      loss: loss,
      optimizer: MomentumOptimizer(),
      epochs: 250,
      batchSize: 3,
      seed: 42);
  if ((model.predict([0.5]).single - 3.5).abs() > 0.001) {
    throw StateError('External model/loss/optimizer integration failed.');
  }

  // Custom loss also works with the built-in dense model.
  final dense = NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42);
  dense.fit(
      inputs: inputs,
      targets: targets,
      loss: loss,
      optimizer: MomentumOptimizer(),
      epochs: 250,
      batchSize: 3);
  if ((dense.predict([0.5]).single - 3.5).abs() > 0.001) {
    throw StateError('Custom loss on Dense failed.');
  }

  // External checkpoint codecs are explicitly supplied; no registry changes.
  final full = TrainingSession<List<double>>(
      model: LinearModel(), optimizer: MomentumOptimizer(), seed: 7);
  final first = TrainingSession<List<double>>(
      model: LinearModel(), optimizer: MomentumOptimizer(), seed: 7);
  full.fit(
      inputs: inputs, targets: targets, loss: loss, epochs: 20, batchSize: 3);
  first.fit(
      inputs: inputs, targets: targets, loss: loss, epochs: 8, batchSize: 3);
  final checkpoint = TrainingCheckpoint.fromJson(
      jsonDecode(jsonEncode(first.checkpoint().toJson()))
          as Map<String, dynamic>);
  final resumed = TrainingSession<List<double>>.restore(
      checkpoint: checkpoint,
      modelDecoder: LinearModel.fromJson,
      optimizerDecoder: MomentumOptimizer.fromJson);
  resumed.fit(
      inputs: inputs, targets: targets, loss: loss, epochs: 12, batchSize: 3);
  if (jsonEncode(full.checkpoint().toJson()) !=
      jsonEncode(resumed.checkpoint().toJson())) {
    throw StateError('External checkpoint continuation diverged.');
  }
  print(
      'External consumer passed: model, Huber loss, momentum optimizer and exact checkpoint replay.');
}

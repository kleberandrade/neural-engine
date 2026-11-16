import 'package:neural_engine/neural_engine.dart';
import '../data/xor_dataset.dart';
import '../data/bar_dataset.dart';
import '../data/sequence_dataset.dart';
import '../data/reconstruction_dataset.dart';

/// UI-independent data and hyperparameters used for start, resume and comparison.
class AsyncDemoRecipe {
  final String family;
  final List<Object> inputs, validationInputs;
  final List<List<double>> targets, validationTargets;
  final TrainingLoss loss;
  final TrainingCheckpoint initial;
  final int batchSize;
  AsyncDemoRecipe._(
      this.family,
      this.inputs,
      this.targets,
      this.validationInputs,
      this.validationTargets,
      this.loss,
      this.initial,
      this.batchSize);

  factory AsyncDemoRecipe(String family) {
    TrainingCheckpoint checkpoint<I>(DifferentiableModel<I> model) =>
        TrainingSession(
                model: model, optimizer: Adam(learningRate: 0.02), seed: 42)
            .checkpoint();
    if (family == 'MLP') {
      return AsyncDemoRecipe._(
          family,
          xorInputs,
          xorTargets,
          xorInputs,
          xorTargets,
          TrainingLoss.binaryCrossEntropy,
          checkpoint(NeuralNetwork(inputSize: 2, seed: 42, layers: [
            Dense(8, activation: Activation.tanh),
            Dense(1, activation: Activation.sigmoid)
          ])),
          4);
    }
    if (family == 'CNN') {
      final train = barDataset();
      final validation = barDataset(seed: 99, repetitions: 1);
      return AsyncDemoRecipe._(
          family,
          train.images,
          train.targets,
          validation.images,
          validation.targets,
          TrainingLoss.categoricalCrossEntropy,
          checkpoint(ConvolutionalNetwork(
              inputHeight: 6,
              inputWidth: 6,
              seed: 42,
              layers: [
                Conv2D(filters: 4, padding: ConvolutionPadding.same),
                MaxPool2D()
              ],
              denseLayers: [
                Dense(2, activation: Activation.softmax)
              ])),
          8);
    }
    if (family == 'Autoencoder') {
      final train = reconstructionDataset();
      final validation = reconstructionDataset(seed: 99);
      return AsyncDemoRecipe._(
          family,
          train.inputs,
          train.targets,
          validation.inputs,
          validation.targets,
          TrainingLoss.binaryCrossEntropy,
          checkpoint(NeuralNetwork(inputSize: 8, seed: 42, layers: [
            Dense(6, activation: Activation.tanh),
            Dense(2, activation: Activation.tanh),
            Dense(6, activation: Activation.tanh),
            Dense(8, activation: Activation.sigmoid)
          ])),
          8);
    }
    final kind = RecurrentKind.values.byName(family.toLowerCase());
    final train = sequenceDataset();
    final validation = sequenceDataset(test: true);
    return AsyncDemoRecipe._(
        family,
        train.inputs,
        train.targets,
        validation.inputs,
        validation.targets,
        TrainingLoss.meanSquaredError,
        checkpoint(RecurrentNetwork(
            inputSize: 1, hiddenSize: 6, outputSize: 1, kind: kind, seed: 42)),
        8);
  }

  AsyncTrainingRequest request(TrainingCheckpoint checkpoint, int epochs) =>
      AsyncTrainingRequest(
          checkpoint: checkpoint,
          inputs: inputs,
          targets: targets,
          validationInputs: validationInputs,
          validationTargets: validationTargets,
          loss: loss,
          epochs: epochs,
          batchSize: batchSize,
          maxGradientNorm: 1);

  List<List<double>> predictions(TrainingCheckpoint checkpoint) {
    if (family == 'CNN') {
      final model = ConvolutionalNetwork.fromJson(checkpoint.model);
      return validationInputs
          .take(4)
          .map((x) => model.predict(x as ImageTensor))
          .toList();
    }
    if (['RNN', 'LSTM', 'GRU'].contains(family)) {
      final model = RecurrentNetwork.fromJson(checkpoint.model);
      return validationInputs
          .take(4)
          .map((x) => model.predict(x as List<List<double>>))
          .toList();
    }
    final model = NeuralNetwork.fromJson(checkpoint.model);
    return validationInputs
        .take(4)
        .map((x) => model.predict(x as List<double>))
        .toList();
  }
}

import '../../contracts/sample_loss_model.dart';
import '../../activations/activation.dart';
import '../../layers/dense.dart';
import '../../losses/loss.dart';
import '../../optimizers/optimizer.dart';
import '../../contracts/differentiable_model.dart';
import '../../contracts/json_model.dart';
import '../../training/mini_batch_trainer.dart';
import '../../training/training_history.dart';
import 'dense_execution.dart';

/// Dense feedforward facade. Training uses the same trainer as CNN/recurrent models.
class NeuralNetwork
    implements
        DifferentiableModel<List<double>>,
        SampleLossModel<List<double>>,
        JsonModel {
  final DenseExecution _execution;
  NeuralNetwork(
      {required int inputSize, required List<Dense> layers, int? seed})
      : _execution =
            DenseExecution(inputSize: inputSize, layers: layers, seed: seed);
  int get inputSize => _execution.inputSize;
  List<Dense> get layers => _execution.layers;
  int? get seed => _execution.seed;
  @override
  int get parameterCount => _execution.parameterCount;
  @override
  List<double> get parameters => _execution.parameters;
  @override
  set parameters(List<double> values) => _execution.parameters = values;
  @override
  List<double> predict(List<double> input) =>
      List.unmodifiable(_execution.forward(input).outputs.last);
  List<List<double>> predictBatch(List<List<double>> inputs) =>
      List.unmodifiable(inputs.map(predict));
  List<List<double>> layerOutputs(List<double> input) =>
      List.unmodifiable(_execution
          .forward(input)
          .outputs
          .skip(1)
          .map((v) => List<double>.unmodifiable(v)));
  @override
  double sampleLoss(
          {required List<double> input,
          required List<double> target,
          required Loss loss}) =>
      _execution.sampleLoss(input: input, target: target, loss: loss);
  @override
  double evaluate(
          {required List<List<double>> inputs,
          required List<List<double>> targets,
          required Loss loss}) =>
      _execution.evaluate(inputs: inputs, targets: targets, loss: loss);
  @override
  List<double> gradients(
          {required List<double> input,
          required List<double> target,
          required Loss loss}) =>
      _execution.gradients(input: input, target: target, loss: loss);
  List<double> inputGradients(
          {required List<double> input,
          required List<double> target,
          required Loss loss}) =>
      _execution.inputGradients(input: input, target: target, loss: loss);
  TrainingHistory fit({
    required List<List<double>> inputs,
    required List<List<double>> targets,
    required Loss loss,
    required Optimizer optimizer,
    int epochs = 1000,
    int batchSize = 32,
    bool shuffle = true,
    List<List<double>>? validationInputs,
    List<List<double>>? validationTargets,
    int? patience,
    double minDelta = 0,
    double? maxGradientNorm,
  }) {
    return MiniBatchTrainer<List<double>>().fit(
        model: this,
        seed: seed,
        inputs: inputs,
        targets: targets,
        loss: loss,
        optimizer: optimizer,
        epochs: epochs,
        batchSize: batchSize,
        shuffle: shuffle,
        validationInputs: validationInputs,
        validationTargets: validationTargets,
        patience: patience,
        minDelta: minDelta,
        maxGradientNorm: maxGradientNorm);
  }

  /// JSON-compatible inference model. Optimizer state is intentionally excluded.
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine',
        'version': 1,
        'inputSize': inputSize,
        'seed': seed,
        'layers': layers
            .map(
              (l) => <String, Object>{
                'units': l.units,
                'activation': l.activation.name,
              },
            )
            .toList(),
        'parameters': List<double>.of(parameters),
      };

  /// Strictly loads a version 1 model, validating dimensions and finite weights.
  factory NeuralNetwork.fromJson(Map<String, dynamic> json) {
    try {
      if (json['format'] != 'neural_engine' || json['version'] != 1) {
        throw const FormatException('Unsupported model format or version.');
      }
      final rawLayers = json['layers'] as List<dynamic>;
      final network = NeuralNetwork(
        inputSize: json['inputSize'] as int,
        seed: json['seed'] as int?,
        layers: rawLayers.map((raw) {
          final l = raw as Map<String, dynamic>;
          return Dense(
            l['units'] as int,
            activation: Activation.values.byName(l['activation'] as String),
          );
        }).toList(),
      );
      network.parameters = (json['parameters'] as List<dynamic>)
          .map((v) => (v as num).toDouble())
          .toList();
      return network;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid neural_engine model: $error');
    }
  }
}

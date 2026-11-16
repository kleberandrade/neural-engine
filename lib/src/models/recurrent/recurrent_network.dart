import '../../contracts/sample_loss_model.dart';
import '../../activations/activation.dart';
import '../../contracts/differentiable_model.dart';
import '../../contracts/json_model.dart';
import '../../layers/dense.dart';
import '../../losses/loss.dart';
import '../../optimizers/optimizer.dart';
import '../../training/mini_batch_trainer.dart';
import '../../training/training_history.dart';
import '../dense/neural_network.dart';
import 'recurrent_kind.dart';
import 'recurrent_cell.dart';
import 'recurrent_state.dart';
import 'recurrent_step.dart';
import 'cells/simple_rnn_cell.dart';
import 'cells/lstm_cell.dart';
import 'cells/gru_cell.dart';

/// Many-to-one recurrent model with a dense projection of the final hidden state.
/// Each sequence starts at zero state; full BPTT, no truncation or padding/masks.
class RecurrentNetwork
    implements
        DifferentiableModel<List<List<double>>>,
        SampleLossModel<List<List<double>>>,
        JsonModel {
  final int inputSize, hiddenSize, outputSize;
  final RecurrentKind kind;
  final Activation outputActivation;
  final int? seed;
  late final RecurrentCell _cell;
  late final NeuralNetwork _head;
  RecurrentNetwork(
      {required this.inputSize,
      required this.hiddenSize,
      required this.outputSize,
      this.kind = RecurrentKind.rnn,
      this.outputActivation = Activation.linear,
      this.seed}) {
    _cell = switch (kind) {
      RecurrentKind.rnn =>
        SimpleRnnCell(inputSize: inputSize, hiddenSize: hiddenSize, seed: seed),
      RecurrentKind.lstm =>
        LstmCell(inputSize: inputSize, hiddenSize: hiddenSize, seed: seed),
      RecurrentKind.gru =>
        GruCell(inputSize: inputSize, hiddenSize: hiddenSize, seed: seed),
    };
    _head = NeuralNetwork(
        inputSize: hiddenSize,
        layers: [Dense(outputSize, activation: outputActivation)],
        seed: seed);
  }
  @override
  int get parameterCount => _cell.parameterCount + _head.parameterCount;
  @override
  List<double> get parameters =>
      List.unmodifiable([..._cell.parameters, ..._head.parameters]);
  @override
  set parameters(List<double> values) {
    if (values.length != parameterCount || values.any((v) => !v.isFinite)) {
      throw ArgumentError('Invalid recurrent parameters.');
    }
    _cell.parameters = values.sublist(0, _cell.parameterCount);
    _head.parameters = values.sublist(_cell.parameterCount);
  }

  List<RecurrentStep> _forward(List<List<double>> input) {
    if (input.isEmpty) {
      throw ArgumentError('A sequence needs at least one timestep.');
    }
    var previous = RecurrentState.zeros(hiddenSize);
    final steps = <RecurrentStep>[];
    for (final vector in input) {
      final step = _cell.forward(vector, previous);
      steps.add(step);
      previous = step.state;
    }
    return steps;
  }

  /// Independent hidden/memory snapshots, one per timestep.
  List<RecurrentState> trace(List<List<double>> input) =>
      List.unmodifiable(_forward(input).map((s) => s.state));
  @override
  List<double> predict(List<List<double>> input) =>
      _head.predict(_forward(input).last.state.hidden);
  @override
  double sampleLoss(
          {required List<List<double>> input,
          required List<double> target,
          required Loss loss}) =>
      _head.sampleLoss(
          input: _forward(input).last.state.hidden, target: target, loss: loss);
  @override
  double evaluate(
      {required List<List<List<double>>> inputs,
      required List<List<double>> targets,
      required Loss loss}) {
    if (inputs.isEmpty || inputs.length != targets.length) {
      throw ArgumentError('Expected matching nonempty sequences and targets.');
    }
    return _head.evaluate(
        inputs: inputs.map((x) => _forward(x).last.state.hidden).toList(),
        targets: targets,
        loss: loss);
  }

  @override
  List<double> gradients(
      {required List<List<double>> input,
      required List<double> target,
      required Loss loss}) {
    final steps = _forward(input);
    final h = steps.last.state.hidden;
    final headGradient = _head.gradients(input: h, target: target, loss: loss);
    var upstream = RecurrentState(
        _head.inputGradients(input: h, target: target, loss: loss),
        List.filled(hiddenSize, 0));
    final gradient = List<double>.filled(_cell.parameterCount, 0);
    for (var t = steps.length - 1; t >= 0; t--) {
      final derivatives = _cell.backward(steps[t], upstream);
      for (var p = 0; p < gradient.length; p++) {
        gradient[p] += derivatives.parameters[p];
      }
      upstream = derivatives.previous;
    }
    final result = [...gradient, ...headGradient];
    if (result.any((v) => !v.isFinite)) {
      throw StateError('Nonfinite BPTT gradient.');
    }
    return List.unmodifiable(result);
  }

  TrainingHistory fit(
          {required List<List<List<double>>> inputs,
          required List<List<double>> targets,
          required Loss loss,
          required Optimizer optimizer,
          int epochs = 200,
          int batchSize = 16,
          bool shuffle = true,
          List<List<List<double>>>? validationInputs,
          List<List<double>>? validationTargets,
          int? patience,
          double minDelta = 0,
          double? maxGradientNorm}) =>
      MiniBatchTrainer<List<List<double>>>().fit(
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
  @override
  Map<String, Object?> toJson() => {
        'format': 'neural_engine_recurrent',
        'version': 1,
        'kind': kind.name,
        'inputSize': inputSize,
        'hiddenSize': hiddenSize,
        'outputSize': outputSize,
        'outputActivation': outputActivation.name,
        'seed': seed,
        'parameters': parameters
      };
  factory RecurrentNetwork.fromJson(Map<String, dynamic> json) {
    try {
      if (json['format'] != 'neural_engine_recurrent' || json['version'] != 1) {
        throw const FormatException('Unsupported recurrent format/version.');
      }
      final model = RecurrentNetwork(
          inputSize: json['inputSize'] as int,
          hiddenSize: json['hiddenSize'] as int,
          outputSize: json['outputSize'] as int,
          kind: RecurrentKind.values.byName(json['kind'] as String),
          outputActivation:
              Activation.values.byName(json['outputActivation'] as String),
          seed: json['seed'] as int?);
      model.parameters = (json['parameters'] as List<dynamic>)
          .map((v) => (v as num).toDouble())
          .toList();
      return model;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid recurrent model: $error');
    }
  }
}

import 'dart:math' as math;
import 'activation.dart';
import 'loss.dart';
import 'optimizer.dart';

/// Immutable losses measured after each completed epoch.
class TrainingHistory {
  final List<double> losses;
  final List<double> validationLosses;
  final bool stoppedEarly;
  final int? bestEpoch;
  int get epochs => losses.length;
  TrainingHistory(
    List<double> losses,
    List<double> validationLosses, {
    required this.stoppedEarly,
    required this.bestEpoch,
  })  : losses = List.unmodifiable(losses),
        validationLosses = List.unmodifiable(validationLosses);
}

/// A dense feedforward network. Training mutates only this network's weights.
/// Parameters use layer order, then neuron order: incoming weights then bias.
class NeuralNetwork {
  final int inputSize;
  final List<Dense> layers;
  final int? seed;
  late List<double> _parameters;
  late final List<int> _offsets;

  NeuralNetwork({
    required this.inputSize,
    required List<Dense> layers,
    this.seed,
  }) : layers = List.unmodifiable(layers) {
    if (inputSize <= 0 || layers.isEmpty) {
      throw ArgumentError(
        'A positive input size and at least one layer are required.',
      );
    }
    _offsets = [];
    _parameters = [];
    final random = math.Random(seed);
    var width = inputSize;
    for (final layer in layers) {
      _offsets.add(_parameters.length);
      // He uniform for ReLU; Glorot uniform otherwise.
      final limit = layer.activation == Activation.relu
          ? math.sqrt(6 / width)
          : math.sqrt(6 / (width + layer.units));
      for (var j = 0; j < layer.units; j++) {
        for (var k = 0; k < width; k++) {
          _parameters.add((random.nextDouble() * 2 - 1) * limit);
        }
        _parameters.add(0);
      }
      width = layer.units;
    }
  }

  int get parameterCount => _parameters.length;

  /// Snapshot, never a reference to mutable network state.
  List<double> get parameters => List.unmodifiable(_parameters);
  set parameters(List<double> values) {
    if (values.length != parameterCount || values.any((x) => !x.isFinite)) {
      throw ArgumentError('Expected $parameterCount finite parameters.');
    }
    _parameters = List.of(values);
  }

  List<double> predict(List<double> input) =>
      List.unmodifiable(_forward(input).outputs.last);
  List<List<double>> predictBatch(List<List<double>> inputs) =>
      List.unmodifiable(inputs.map(predict));

  /// Immutable output of each Dense layer, excluding the input vector.
  /// Autoencoders can inspect their bottleneck through this method.
  List<List<double>> layerOutputs(List<double> input) => List.unmodifiable(
      _forward(input).outputs.skip(1).map((v) => List<double>.unmodifiable(v)));

  _Pass _forward(List<double> input) {
    _vector(input, inputSize, 'input');
    final outputs = <List<double>>[List.of(input)];
    final logits = <List<double>>[];
    for (var l = 0; l < layers.length; l++) {
      final previous = outputs.last;
      final z = List.generate(layers[l].units, (j) {
        final base = _offsets[l] + j * (previous.length + 1);
        var sum = _parameters[base + previous.length];
        for (var k = 0; k < previous.length; k++) {
          sum += previous[k] * _parameters[base + k];
        }
        if (!sum.isFinite) {
          throw StateError(
            'Nonfinite preactivation; rescale data or learning rate.',
          );
        }
        return sum;
      });
      logits.add(z);
      outputs.add(layers[l].activation.forward(z));
    }
    return _Pass(outputs, logits);
  }

  void _compatible(Loss loss) {
    if (loss is BinaryCrossEntropy &&
            layers.last.activation != Activation.sigmoid ||
        loss is CategoricalCrossEntropy &&
            layers.last.activation != Activation.softmax) {
      throw ArgumentError(
        'BCE requires sigmoid; categorical cross entropy requires softmax.',
      );
    }
  }

  double _sampleLoss(_Pass pass, List<double> target, Loss loss) {
    // Validates custom loss output and built-in target domains too.
    final ordinary = loss.value(pass.outputs.last, target);
    if (!ordinary.isFinite) throw StateError('Loss must be finite.');
    final z = pass.logits.last;
    if (loss is BinaryCrossEntropy) {
      var sum = 0.0;
      for (var i = 0; i < z.length; i++) {
        sum += math.max(z[i], 0) -
            z[i] * target[i] +
            math.log(1 + math.exp(-z[i].abs()));
      }
      return sum / z.length;
    }
    if (loss is CategoricalCrossEntropy) {
      final max = z.reduce(math.max);
      final logSum = math.log(
        z.map((x) => math.exp(x - max)).reduce((a, b) => a + b),
      );
      var sum = 0.0;
      for (var i = 0; i < z.length; i++) {
        sum += target[i] * (max - z[i] + logSum);
      }
      return sum;
    }
    return ordinary;
  }

  /// Loss averaged over samples (MSE and BCE also average over outputs).
  double evaluate({
    required List<List<double>> inputs,
    required List<List<double>> targets,
    required Loss loss,
  }) {
    _compatible(loss);
    _dataset(inputs, targets);
    var total = 0.0;
    for (var i = 0; i < inputs.length; i++) {
      total += _sampleLoss(_forward(inputs[i]), targets[i], loss);
    }
    final result = total / inputs.length;
    if (!result.isFinite) throw StateError('Nonfinite average loss.');
    return result;
  }

  /// Analytic sample gradient in the same order as [parameters].
  List<double> gradients({
    required List<double> input,
    required List<double> target,
    required Loss loss,
  }) {
    return _differentiate(input: input, target: target, loss: loss).parameters;
  }

  /// Derivative of the sample loss with respect to each input coordinate.
  /// Useful when composing a dense head with other differentiable models.
  List<double> inputGradients(
          {required List<double> input,
          required List<double> target,
          required Loss loss}) =>
      _differentiate(input: input, target: target, loss: loss).input;

  _Derivatives _differentiate(
      {required List<double> input,
      required List<double> target,
      required Loss loss}) {
    _compatible(loss);
    _vector(target, layers.last.units, 'target');
    final pass = _forward(input);
    _sampleLoss(pass, target, loss);
    final prediction = pass.outputs.last;
    var delta = loss is BinaryCrossEntropy
        ? List.generate(
            prediction.length,
            (i) => (prediction[i] - target[i]) / prediction.length,
          )
        : loss is CategoricalCrossEntropy
            ? List.generate(prediction.length, (i) => prediction[i] - target[i])
            : layers.last.activation.backward(
                prediction,
                loss.gradient(prediction, target),
              );
    final result = List<double>.filled(parameterCount, 0);
    var inputGradient = <double>[];
    for (var l = layers.length - 1; l >= 0; l--) {
      final previous = pass.outputs[l];
      final upstream = List<double>.filled(previous.length, 0);
      for (var j = 0; j < layers[l].units; j++) {
        final base = _offsets[l] + j * (previous.length + 1);
        for (var k = 0; k < previous.length; k++) {
          result[base + k] = delta[j] * previous[k];
          upstream[k] += delta[j] * _parameters[base + k];
        }
        result[base + previous.length] = delta[j];
      }
      if (l > 0) {
        delta = layers[l - 1].activation.backward(previous, upstream);
      } else {
        inputGradient = upstream;
      }
    }
    if ([...result, ...inputGradient].any((x) => !x.isFinite)) {
      throw StateError('Nonfinite gradient.');
    }
    return _Derivatives(
        List.unmodifiable(result), List.unmodifiable(inputGradient));
  }

  /// Fits mini-batches synchronously. Each call starts fresh optimizer state.
  /// Early stopping requires validation data and restores the best epoch.
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
  }) {
    if (epochs <= 0 ||
        batchSize <= 0 ||
        !minDelta.isFinite ||
        minDelta < 0 ||
        (patience != null && patience <= 0) ||
        (validationInputs == null) != (validationTargets == null) ||
        (patience != null && validationInputs == null)) {
      throw ArgumentError('Invalid training or validation configuration.');
    }
    // Validate complete datasets before any weight updates.
    evaluate(inputs: inputs, targets: targets, loss: loss);
    if (validationInputs != null) {
      evaluate(
        inputs: validationInputs,
        targets: validationTargets!,
        loss: loss,
      );
    }
    final state = optimizer.createState(parameterCount);
    final random = math.Random(seed);
    final order = List.generate(inputs.length, (i) => i);
    final losses = <double>[];
    final validationLosses = <double>[];
    var best = double.infinity;
    List<double>? bestParameters;
    int? bestEpoch;
    var stale = 0;
    var stopped = false;
    for (var epoch = 0; epoch < epochs; epoch++) {
      if (shuffle) order.shuffle(random);
      for (var start = 0; start < order.length; start += batchSize) {
        final end = math.min(start + batchSize, order.length);
        final average = List<double>.filled(parameterCount, 0);
        for (var n = start; n < end; n++) {
          final i = order[n];
          final g = gradients(input: inputs[i], target: targets[i], loss: loss);
          for (var p = 0; p < parameterCount; p++) {
            average[p] += g[p] / (end - start);
          }
        }
        // Candidate updates make optimizer overflow failures atomic per batch.
        final candidate = List<double>.of(_parameters);
        state.update(candidate, average);
        if (candidate.any((x) => !x.isFinite)) {
          throw StateError(
            'Optimizer produced nonfinite weights; lower the learning rate.',
          );
        }
        _parameters = candidate;
      }
      losses.add(evaluate(inputs: inputs, targets: targets, loss: loss));
      if (validationInputs != null) {
        final value = evaluate(
          inputs: validationInputs,
          targets: validationTargets!,
          loss: loss,
        );
        validationLosses.add(value);
        if (value < best - minDelta) {
          best = value;
          bestParameters = List.of(_parameters);
          bestEpoch = epoch + 1;
          stale = 0;
        } else {
          stale++;
        }
        if (patience != null && stale >= patience) {
          stopped = true;
          break;
        }
      }
    }
    if (patience != null && bestParameters != null) {
      _parameters = bestParameters;
    }
    return TrainingHistory(
      losses,
      validationLosses,
      stoppedEarly: stopped,
      bestEpoch: bestEpoch,
    );
  }

  void _dataset(List<List<double>> inputs, List<List<double>> targets) {
    if (inputs.isEmpty || inputs.length != targets.length) {
      throw ArgumentError(
        'Datasets must be nonempty with matching sample counts.',
      );
    }
    for (var i = 0; i < inputs.length; i++) {
      _vector(inputs[i], inputSize, 'input');
      _vector(targets[i], layers.last.units, 'target');
    }
  }

  /// JSON-compatible inference model. Optimizer state is intentionally excluded.
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
        'parameters': List<double>.of(_parameters),
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

class _Pass {
  final List<List<double>> outputs;
  final List<List<double>> logits;
  _Pass(this.outputs, this.logits);
}

void _vector(List<double> values, int size, String label) {
  if (values.length != size || values.any((x) => !x.isFinite)) {
    throw ArgumentError('$label must contain $size finite values.');
  }
}

class _Derivatives {
  final List<double> parameters;
  final List<double> input;
  _Derivatives(this.parameters, this.input);
}

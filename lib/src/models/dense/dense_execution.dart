import 'dart:math' as math;
import '../../activations/activation.dart';
import '../../layers/dense.dart';
import '../../losses/loss.dart';
import '../../losses/binary_cross_entropy.dart';
import '../../losses/categorical_cross_entropy.dart';
import 'dense_pass.dart';

class DenseExecution {
  final int inputSize;
  final List<Dense> layers;
  final int? seed;
  late List<double> _parameters;
  late final List<int> _offsets;

  DenseExecution({
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

  DensePass forward(List<double> input) {
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
    return DensePass(outputs, logits);
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

  double _sampleLoss(DensePass pass, List<double> target, Loss loss) {
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
      total += _sampleLoss(forward(inputs[i]), targets[i], loss);
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
    return differentiate(input: input, target: target, loss: loss).parameters;
  }

  /// Derivative of the sample loss with respect to each input coordinate.
  /// Useful when composing a dense head with other differentiable models.
  List<double> inputGradients(
          {required List<double> input,
          required List<double> target,
          required Loss loss}) =>
      differentiate(input: input, target: target, loss: loss).input;

  DenseDerivatives differentiate(
      {required List<double> input,
      required List<double> target,
      required Loss loss}) {
    _compatible(loss);
    _vector(target, layers.last.units, 'target');
    final pass = forward(input);
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
    return DenseDerivatives(
        List.unmodifiable(result), List.unmodifiable(inputGradient));
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
}

void _vector(List<double> values, int size, String label) {
  if (values.length != size || values.any((x) => !x.isFinite)) {
    throw ArgumentError('$label must contain $size finite values.');
  }
}

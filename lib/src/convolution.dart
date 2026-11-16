import 'dart:math' as math;
import 'activation.dart';
import 'loss.dart';
import 'network.dart';
import 'optimizer.dart';

/// Immutable height × width × channels tensor, flattened in HWC order.
class ImageTensor {
  final int height;
  final int width;
  final int channels;
  final List<double> values;
  ImageTensor(
      {required this.height,
      required this.width,
      required this.channels,
      required List<double> values})
      : values = List.unmodifiable(values) {
    if (height <= 0 ||
        width <= 0 ||
        channels <= 0 ||
        values.length != height * width * channels ||
        values.any((v) => !v.isFinite)) {
      throw ArgumentError(
          'ImageTensor needs positive HWC dimensions and matching finite values.');
    }
  }
  double at(int row, int column, int channel) {
    if (row < 0 ||
        row >= height ||
        column < 0 ||
        column >= width ||
        channel < 0 ||
        channel >= channels) {
      throw RangeError('Tensor coordinate outside HWC dimensions.');
    }
    return values[(row * width + column) * channels + channel];
  }
}

/// Same uses zero padding, with extra padding at bottom/right for odd totals.
enum ConvolutionPadding { valid, same }

/// Spatial feature extractor specification; flattening before Dense is implicit.
sealed class SpatialLayer {
  const SpatialLayer();
}

/// Trainable 2D cross-correlation (the convention used by CNN libraries).
final class Conv2D extends SpatialLayer {
  final int filters;
  final int kernelSize;
  final int stride;
  final ConvolutionPadding padding;
  final Activation activation;
  Conv2D(
      {required this.filters,
      this.kernelSize = 3,
      this.stride = 1,
      this.padding = ConvolutionPadding.valid,
      this.activation = Activation.relu}) {
    if (filters <= 0 ||
        kernelSize <= 0 ||
        stride <= 0 ||
        activation == Activation.softmax) {
      throw ArgumentError(
          'Conv2D needs positive dimensions and an elementwise activation.');
    }
  }
}

/// Nontrainable valid max pooling per channel; ties route to first HWC position.
final class MaxPool2D extends SpatialLayer {
  final int poolSize;
  final int stride;
  MaxPool2D({this.poolSize = 2, this.stride = 2}) {
    if (poolSize <= 0 || stride <= 0) {
      throw ArgumentError('Pool dimensions must be positive.');
    }
  }
}

/// A stack of Conv2D/MaxPool2D layers, implicit Flatten and a dense head.
/// Backpropagation trains convolution kernels and the dense head together.
class ConvolutionalNetwork {
  final int inputHeight;
  final int inputWidth;
  final int inputChannels;
  final int? seed;
  final List<SpatialLayer> layers;
  late final List<_Stage> _stages;
  late final NeuralNetwork _head;
  late List<double> _spatialParameters;

  ConvolutionalNetwork(
      {required this.inputHeight,
      required this.inputWidth,
      this.inputChannels = 1,
      required List<SpatialLayer> layers,
      required List<Dense> denseLayers,
      this.seed})
      : layers = List.unmodifiable(layers) {
    if (inputHeight <= 0 ||
        inputWidth <= 0 ||
        inputChannels <= 0 ||
        layers.isEmpty ||
        !layers.any((l) => l is Conv2D)) {
      throw ArgumentError(
          'CNN requires a positive input shape and at least one Conv2D.');
    }
    _stages = [];
    _spatialParameters = [];
    final random = math.Random(seed);
    var h = inputHeight;
    var w = inputWidth;
    var c = inputChannels;
    for (final layer in layers) {
      final stage = _Stage(layer, h, w, c, _spatialParameters.length);
      _stages.add(stage);
      if (layer is Conv2D) {
        final fanIn = layer.kernelSize * layer.kernelSize * c;
        final fanOut = layer.kernelSize * layer.kernelSize * layer.filters;
        final limit = layer.activation == Activation.relu
            ? math.sqrt(6 / fanIn)
            : math.sqrt(6 / (fanIn + fanOut));
        for (var f = 0; f < layer.filters; f++) {
          for (var k = 0; k < fanIn; k++) {
            _spatialParameters.add((random.nextDouble() * 2 - 1) * limit);
          }
          _spatialParameters.add(0);
        }
      }
      h = stage.oh;
      w = stage.ow;
      c = stage.oc;
    }
    _head =
        NeuralNetwork(inputSize: h * w * c, layers: denseLayers, seed: seed);
  }

  int get parameterCount => _spatialParameters.length + _head.parameterCount;

  /// Kernels in filter/ky/kx/channel order, each followed by bias, then Dense.
  List<double> get parameters =>
      List.unmodifiable([..._spatialParameters, ..._head.parameters]);
  set parameters(List<double> values) {
    if (values.length != parameterCount || values.any((v) => !v.isFinite)) {
      throw ArgumentError('Expected $parameterCount finite CNN parameters.');
    }
    final n = _spatialParameters.length;
    _spatialParameters = values.sublist(0, n);
    _head.parameters = values.sublist(n);
  }

  void _shape(ImageTensor input) {
    if (input.height != inputHeight ||
        input.width != inputWidth ||
        input.channels != inputChannels) {
      throw ArgumentError('Unexpected input HWC shape.');
    }
  }

  _FeaturePass _forward(ImageTensor input) {
    _shape(input);
    final tensors = <ImageTensor>[input];
    final switches = <List<int>>[];
    for (final stage in _stages) {
      final x = tensors.last.values;
      final output = List<double>.filled(stage.oh * stage.ow * stage.oc, 0);
      final routes = List<int>.filled(output.length, -1);
      final spec = stage.spec;
      for (var oy = 0; oy < stage.oh; oy++) {
        for (var ox = 0; ox < stage.ow; ox++) {
          for (var oc = 0; oc < stage.oc; oc++) {
            final out = (oy * stage.ow + ox) * stage.oc + oc;
            if (spec is Conv2D) {
              final base = stage.offset +
                  oc * (spec.kernelSize * spec.kernelSize * stage.ic + 1);
              var sum = _spatialParameters[
                  base + spec.kernelSize * spec.kernelSize * stage.ic];
              for (var ky = 0; ky < spec.kernelSize; ky++) {
                final iy = oy * spec.stride + ky - stage.padY;
                if (iy < 0 || iy >= stage.ih) continue;
                for (var kx = 0; kx < spec.kernelSize; kx++) {
                  final ix = ox * spec.stride + kx - stage.padX;
                  if (ix < 0 || ix >= stage.iw) continue;
                  for (var ic = 0; ic < stage.ic; ic++) {
                    final p =
                        base + (ky * spec.kernelSize + kx) * stage.ic + ic;
                    sum += x[(iy * stage.iw + ix) * stage.ic + ic] *
                        _spatialParameters[p];
                  }
                }
              }
              output[out] = sum;
            } else if (spec is MaxPool2D) {
              var best = double.negativeInfinity;
              for (var ky = 0; ky < spec.poolSize; ky++) {
                for (var kx = 0; kx < spec.poolSize; kx++) {
                  final index = ((oy * spec.stride + ky) * stage.iw +
                              ox * spec.stride +
                              kx) *
                          stage.ic +
                      oc;
                  if (x[index] > best) {
                    best = x[index];
                    routes[out] = index;
                  }
                }
              }
              output[out] = best;
            }
          }
        }
      }
      final activated =
          spec is Conv2D ? spec.activation.forward(output) : output;
      tensors.add(ImageTensor(
          height: stage.oh,
          width: stage.ow,
          channels: stage.oc,
          values: activated));
      switches.add(routes);
    }
    return _FeaturePass(tensors, switches);
  }

  List<double> predict(ImageTensor input) =>
      _head.predict(_forward(input).tensors.last.values);

  /// Immutable spatial activations after each layer, useful for visualization.
  List<ImageTensor> featureMaps(ImageTensor input) =>
      List.unmodifiable(_forward(input).tensors.skip(1));

  double evaluate(
      {required List<ImageTensor> inputs,
      required List<List<double>> targets,
      required Loss loss}) {
    if (inputs.isEmpty || inputs.length != targets.length) {
      throw ArgumentError('Expected matching nonempty datasets.');
    }
    return _head.evaluate(
        inputs: inputs.map((x) => _forward(x).tensors.last.values).toList(),
        targets: targets,
        loss: loss);
  }

  /// Sample derivatives in [parameters] order, including trainable kernels.
  List<double> gradients(
      {required ImageTensor input,
      required List<double> target,
      required Loss loss}) {
    final pass = _forward(input);
    final flat = pass.tensors.last.values;
    final headGradient =
        _head.gradients(input: flat, target: target, loss: loss);
    var upstream =
        _head.inputGradients(input: flat, target: target, loss: loss);
    final result = List<double>.filled(_spatialParameters.length, 0);
    for (var l = _stages.length - 1; l >= 0; l--) {
      final stage = _stages[l];
      final spec = stage.spec;
      final previous = pass.tensors[l].values;
      final inputGradient = List<double>.filled(previous.length, 0);
      if (spec is MaxPool2D) {
        for (var i = 0; i < upstream.length; i++) {
          inputGradient[pass.switches[l][i]] += upstream[i];
        }
      } else if (spec is Conv2D) {
        final delta =
            spec.activation.backward(pass.tensors[l + 1].values, upstream);
        for (var oy = 0; oy < stage.oh; oy++) {
          for (var ox = 0; ox < stage.ow; ox++) {
            for (var oc = 0; oc < stage.oc; oc++) {
              final d = delta[(oy * stage.ow + ox) * stage.oc + oc];
              final base = stage.offset +
                  oc * (spec.kernelSize * spec.kernelSize * stage.ic + 1);
              result[base + spec.kernelSize * spec.kernelSize * stage.ic] += d;
              for (var ky = 0; ky < spec.kernelSize; ky++) {
                final iy = oy * spec.stride + ky - stage.padY;
                if (iy < 0 || iy >= stage.ih) continue;
                for (var kx = 0; kx < spec.kernelSize; kx++) {
                  final ix = ox * spec.stride + kx - stage.padX;
                  if (ix < 0 || ix >= stage.iw) continue;
                  for (var ic = 0; ic < stage.ic; ic++) {
                    final p =
                        base + (ky * spec.kernelSize + kx) * stage.ic + ic;
                    final index = (iy * stage.iw + ix) * stage.ic + ic;
                    result[p] += d * previous[index];
                    inputGradient[index] += d * _spatialParameters[p];
                  }
                }
              }
            }
          }
        }
      }
      upstream = inputGradient;
    }
    final all = [...result, ...headGradient];
    if (all.any((v) => !v.isFinite)) {
      throw StateError('Nonfinite CNN gradient.');
    }
    return List.unmodifiable(all);
  }

  /// End-to-end mini-batch training; optimizer state is fresh per invocation.
  /// This initial CNN trainer records training loss; validation/early stopping
  /// are currently available only on the dense NeuralNetwork trainer.
  TrainingHistory fit(
      {required List<ImageTensor> inputs,
      required List<List<double>> targets,
      required Loss loss,
      required Optimizer optimizer,
      int epochs = 100,
      int batchSize = 16,
      bool shuffle = true}) {
    if (epochs <= 0 || batchSize <= 0) {
      throw ArgumentError('Positive epochs and batch size required.');
    }
    evaluate(inputs: inputs, targets: targets, loss: loss);
    final state = optimizer.createState(parameterCount);
    final order = List.generate(inputs.length, (i) => i);
    final random = math.Random(seed);
    final losses = <double>[];
    for (var epoch = 0; epoch < epochs; epoch++) {
      if (shuffle) order.shuffle(random);
      for (var start = 0; start < order.length; start += batchSize) {
        final end = math.min(start + batchSize, order.length);
        final average = List<double>.filled(parameterCount, 0);
        for (var n = start; n < end; n++) {
          final index = order[n];
          final g = gradients(
              input: inputs[index], target: targets[index], loss: loss);
          for (var p = 0; p < average.length; p++) {
            average[p] += g[p] / (end - start);
          }
        }
        final candidate = List<double>.of(parameters);
        state.update(candidate, average);
        if (candidate.length != parameterCount ||
            candidate.any((v) => !v.isFinite)) {
          throw StateError('Optimizer produced invalid CNN parameters.');
        }
        parameters = candidate;
      }
      losses.add(evaluate(inputs: inputs, targets: targets, loss: loss));
    }
    return TrainingHistory(losses, const [],
        stoppedEarly: false, bestEpoch: null);
  }

  Map<String, Object?> toJson() => {
        'format': 'neural_engine_cnn',
        'version': 1,
        'inputHeight': inputHeight,
        'inputWidth': inputWidth,
        'inputChannels': inputChannels,
        'seed': seed,
        'layers': layers
            .map((l) => switch (l) {
                  Conv2D() => <String, Object>{
                      'type': 'conv2d',
                      'filters': l.filters,
                      'kernelSize': l.kernelSize,
                      'stride': l.stride,
                      'padding': l.padding.name,
                      'activation': l.activation.name
                    },
                  MaxPool2D() => <String, Object>{
                      'type': 'maxpool2d',
                      'poolSize': l.poolSize,
                      'stride': l.stride
                    },
                })
            .toList(),
        'spatialParameters': List.of(_spatialParameters),
        'head': _head.toJson()
      };

  factory ConvolutionalNetwork.fromJson(Map<String, dynamic> json) {
    try {
      if (json['format'] != 'neural_engine_cnn' || json['version'] != 1) {
        throw const FormatException('Unsupported CNN format/version.');
      }
      final head = NeuralNetwork.fromJson(json['head'] as Map<String, dynamic>);
      final layers = (json['layers'] as List<dynamic>).map((raw) {
        final l = raw as Map<String, dynamic>;
        return switch (l['type']) {
          'conv2d' => Conv2D(
              filters: l['filters'] as int,
              kernelSize: l['kernelSize'] as int,
              stride: l['stride'] as int,
              padding: ConvolutionPadding.values.byName(l['padding'] as String),
              activation: Activation.values.byName(l['activation'] as String)),
          'maxpool2d' => MaxPool2D(
              poolSize: l['poolSize'] as int, stride: l['stride'] as int),
          _ => throw const FormatException('Unknown spatial layer.'),
        };
      }).toList();
      final model = ConvolutionalNetwork(
          inputHeight: json['inputHeight'] as int,
          inputWidth: json['inputWidth'] as int,
          inputChannels: json['inputChannels'] as int,
          layers: layers,
          denseLayers: head.layers,
          seed: json['seed'] as int?);
      if (model._head.inputSize != head.inputSize) {
        throw const FormatException('Dense head shape mismatch.');
      }
      model.parameters = [
        ...(json['spatialParameters'] as List<dynamic>)
            .map((v) => (v as num).toDouble()),
        ...head.parameters
      ];
      return model;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid CNN model: $error');
    }
  }
}

class _Stage {
  final SpatialLayer spec;
  final int ih, iw, ic, offset;
  late final int oh, ow, oc, padY, padX;
  _Stage(this.spec, this.ih, this.iw, this.ic, this.offset) {
    final layer = spec;
    final kernel =
        layer is Conv2D ? layer.kernelSize : (layer as MaxPool2D).poolSize;
    final stride = layer is Conv2D ? layer.stride : (layer as MaxPool2D).stride;
    final same = layer is Conv2D && layer.padding == ConvolutionPadding.same;
    if (!same && (ih < kernel || iw < kernel)) {
      throw ArgumentError('Spatial kernel exceeds input shape.');
    }
    oh = same ? (ih + stride - 1) ~/ stride : (ih - kernel) ~/ stride + 1;
    ow = same ? (iw + stride - 1) ~/ stride : (iw - kernel) ~/ stride + 1;
    oc = layer is Conv2D ? layer.filters : ic;
    padY = same ? math.max(0, (oh - 1) * stride + kernel - ih) ~/ 2 : 0;
    padX = same ? math.max(0, (ow - 1) * stride + kernel - iw) ~/ 2 : 0;
  }
}

class _FeaturePass {
  final List<ImageTensor> tensors;
  final List<List<int>> switches;
  _FeaturePass(this.tensors, this.switches);
}

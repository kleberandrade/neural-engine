import '../../activations/activation.dart';
import '../../layers/spatial/conv2d.dart';
import '../../layers/spatial/max_pool2d.dart';
import '../../layers/spatial/spatial_layer.dart';
import '../../layers/spatial/convolution_padding.dart';
import '../../tensors/image_tensor.dart';
import 'dart:math' as math;
import '../../contracts/differentiable_model.dart';
import '../../contracts/json_model.dart';
import '../../layers/dense.dart';
import '../../models/dense/neural_network.dart';
import '../../losses/loss.dart';
import '../../optimizers/optimizer.dart';
import '../../training/mini_batch_trainer.dart';
import '../../training/training_history.dart';
import 'spatial_stage.dart';
import 'spatial_pass.dart';
import 'spatial_forward.dart';
import 'spatial_backward.dart';

/// A stack of Conv2D/MaxPool2D layers, implicit Flatten and a dense head.
/// Backpropagation trains convolution kernels and the dense head together.
class ConvolutionalNetwork
    implements DifferentiableModel<ImageTensor>, JsonModel {
  final int inputHeight;
  final int inputWidth;
  final int inputChannels;
  final int? seed;
  final List<SpatialLayer> layers;
  late final List<SpatialStage> _stages;
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
      final stage = SpatialStage(layer, h, w, c, _spatialParameters.length);
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

  @override
  int get parameterCount => _spatialParameters.length + _head.parameterCount;

  /// Kernels in filter/ky/kx/channel order, each followed by bias, then Dense.
  @override
  List<double> get parameters =>
      List.unmodifiable([..._spatialParameters, ..._head.parameters]);
  @override
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

  SpatialPass _forward(ImageTensor input) {
    _shape(input);
    return spatialForward(input, _stages, _spatialParameters);
  }

  @override
  List<double> predict(ImageTensor input) =>
      _head.predict(_forward(input).tensors.last.values);

  /// Immutable spatial activations after each layer, useful for visualization.
  List<ImageTensor> featureMaps(ImageTensor input) =>
      List.unmodifiable(_forward(input).tensors.skip(1));

  @override
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
  @override
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
    return List.unmodifiable([
      ...spatialBackward(pass, _stages, _spatialParameters, upstream),
      ...headGradient
    ]);
  }

  /// Shared trainer with validation, early stopping and optional gradient clipping.
  TrainingHistory fit(
          {required List<ImageTensor> inputs,
          required List<List<double>> targets,
          required Loss loss,
          required Optimizer optimizer,
          int epochs = 100,
          int batchSize = 16,
          bool shuffle = true,
          List<ImageTensor>? validationInputs,
          List<List<double>>? validationTargets,
          int? patience,
          double minDelta = 0,
          double? maxGradientNorm}) =>
      MiniBatchTrainer<ImageTensor>().fit(
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
                  _ => throw ArgumentError(
                      'Unsupported spatial layer serialization.'),
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

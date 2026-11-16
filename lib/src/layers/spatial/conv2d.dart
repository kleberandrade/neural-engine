import '../../activations/activation.dart';
import 'spatial_layer.dart';
import 'convolution_padding.dart';

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

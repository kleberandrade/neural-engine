import 'dart:math' as math;
import '../../layers/spatial/conv2d.dart';
import '../../layers/spatial/max_pool2d.dart';
import '../../layers/spatial/spatial_layer.dart';
import '../../layers/spatial/convolution_padding.dart';

class SpatialStage {
  final SpatialLayer spec;
  final int ih, iw, ic, offset;
  late final int oh, ow, oc, padY, padX;
  SpatialStage(this.spec, this.ih, this.iw, this.ic, this.offset) {
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

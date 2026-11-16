import 'spatial_layer.dart';

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

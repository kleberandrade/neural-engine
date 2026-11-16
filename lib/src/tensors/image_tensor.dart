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

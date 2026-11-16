import 'dart:math' as math;
import '../../../activations/activation.dart';

/// Shared affine gate storage; gate rows contain x weights, h weights, bias.
class CellWeights {
  final int inputSize, hiddenSize, gates;
  late List<double> _values;
  int get gateSize => hiddenSize * (inputSize + hiddenSize + 1);
  int get parameterCount => gates * gateSize;
  CellWeights(this.inputSize, this.hiddenSize, this.gates, int? seed) {
    if (inputSize <= 0 || hiddenSize <= 0) {
      throw ArgumentError('Cell dimensions must be positive.');
    }
    final r = math.Random(seed);
    final limit = math.sqrt(6 / (inputSize + 2 * hiddenSize));
    _values = List.generate(
        parameterCount,
        (i) => i % (inputSize + hiddenSize + 1) == inputSize + hiddenSize
            ? 0
            : (2 * r.nextDouble() - 1) * limit);
  }
  List<double> get values => List.unmodifiable(_values);
  set values(List<double> v) {
    if (v.length != parameterCount || v.any((x) => !x.isFinite)) {
      throw ArgumentError('Invalid cell parameters.');
    }
    _values = List.of(v);
  }

  List<double> gate(
      int gate, List<double> x, List<double> h, Activation activation) {
    if (x.length != inputSize ||
        h.length != hiddenSize ||
        [...x, ...h].any((v) => !v.isFinite)) {
      throw ArgumentError('Invalid recurrent input/state.');
    }
    return activation.forward(List.generate(hiddenSize, (j) {
      final base = gate * gateSize + j * (inputSize + hiddenSize + 1);
      var y = _values[base + inputSize + hiddenSize];
      for (var i = 0; i < inputSize; i++) {
        y += _values[base + i] * x[i];
      }
      for (var i = 0; i < hiddenSize; i++) {
        y += _values[base + inputSize + i] * h[i];
      }
      return y;
    }));
  }

  void accumulate(int gate, List<double> x, List<double> h, List<double> delta,
      List<double> dp, List<double> dx, List<double> dh) {
    for (var j = 0; j < hiddenSize; j++) {
      final base = gate * gateSize + j * (inputSize + hiddenSize + 1);
      for (var i = 0; i < inputSize; i++) {
        dp[base + i] += delta[j] * x[i];
        dx[i] += _values[base + i] * delta[j];
      }
      for (var i = 0; i < hiddenSize; i++) {
        dp[base + inputSize + i] += delta[j] * h[i];
        dh[i] += _values[base + inputSize + i] * delta[j];
      }
      dp[base + inputSize + hiddenSize] += delta[j];
    }
  }
}

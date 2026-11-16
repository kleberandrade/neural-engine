import '../../../activations/activation.dart';
import '../recurrent_cell.dart';
import '../recurrent_state.dart';
import '../recurrent_step.dart';
import '../recurrent_derivatives.dart';
import 'cell_weights.dart';

/// Reset-before GRU: n=tanh(Wx+U(r*h)); h=(1-z)*n+z*h_previous.
/// Gate order: update, reset, candidate. Not Keras reset-after weight compatible.
class GruCell implements RecurrentCell {
  final CellWeights _weights;
  GruCell({required int inputSize, required int hiddenSize, int? seed})
      : _weights = CellWeights(inputSize, hiddenSize, 3, seed);
  @override
  int get inputSize => _weights.inputSize;
  @override
  int get hiddenSize => _weights.hiddenSize;
  @override
  int get parameterCount => _weights.parameterCount;
  @override
  List<double> get parameters => _weights.values;
  @override
  set parameters(List<double> values) => _weights.values = values;
  @override
  RecurrentStep forward(List<double> input, RecurrentState previous) {
    final z = _weights.gate(0, input, previous.hidden, Activation.sigmoid);
    final r = _weights.gate(1, input, previous.hidden, Activation.sigmoid);
    final rh = List.generate(hiddenSize, (j) => r[j] * previous.hidden[j]);
    final n = _weights.gate(2, input, rh, Activation.tanh);
    final h = List.generate(
        hiddenSize, (j) => (1 - z[j]) * n[j] + z[j] * previous.hidden[j]);
    return RecurrentStep(RecurrentState(h, List.filled(hiddenSize, 0)),
        _Cache(List.of(input), previous, [z, r, rh, n]));
  }

  @override
  RecurrentDerivatives backward(RecurrentStep step, RecurrentState upstream) {
    final cache = step.cache as _Cache;
    final z = cache.gates[0],
        r = cache.gates[1],
        rh = cache.gates[2],
        n = cache.gates[3];
    final dp = List<double>.filled(parameterCount, 0),
        dx = List<double>.filled(inputSize, 0),
        dh = List<double>.filled(hiddenSize, 0),
        drh = List<double>.filled(hiddenSize, 0);
    final dn = List.generate(
        hiddenSize, (j) => upstream.hidden[j] * (1 - z[j]) * (1 - n[j] * n[j]));
    _weights.accumulate(2, cache.input, rh, dn, dp, dx, drh);
    final dz = List.generate(
        hiddenSize,
        (j) =>
            upstream.hidden[j] *
            (cache.previous.hidden[j] - n[j]) *
            z[j] *
            (1 - z[j]));
    final dr = List.generate(hiddenSize,
        (j) => drh[j] * cache.previous.hidden[j] * r[j] * (1 - r[j]));
    for (var j = 0; j < hiddenSize; j++) {
      dh[j] = upstream.hidden[j] * z[j] + drh[j] * r[j];
    }
    _weights.accumulate(0, cache.input, cache.previous.hidden, dz, dp, dx, dh);
    _weights.accumulate(1, cache.input, cache.previous.hidden, dr, dp, dx, dh);
    return RecurrentDerivatives(
        dp, dx, RecurrentState(dh, List.filled(hiddenSize, 0)));
  }
}

class _Cache extends CellCache {
  final List<double> input;
  final RecurrentState previous;
  final List<List<double>> gates;
  _Cache(this.input, this.previous, this.gates);
}

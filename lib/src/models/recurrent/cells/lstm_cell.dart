import '../../../activations/activation.dart';
import '../recurrent_cell.dart';
import '../recurrent_state.dart';
import '../recurrent_step.dart';
import '../recurrent_derivatives.dart';
import 'cell_weights.dart';

/// LSTM without peepholes. Gate order: input, forget, output, candidate.
class LstmCell implements RecurrentCell {
  final CellWeights _weights;
  LstmCell({required int inputSize, required int hiddenSize, int? seed})
      : _weights = CellWeights(inputSize, hiddenSize, 4, seed);
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
    if (previous.memory.length != hiddenSize ||
        previous.memory.any((v) => !v.isFinite)) {
      throw ArgumentError('Invalid LSTM memory.');
    }
    final i = _weights.gate(0, input, previous.hidden, Activation.sigmoid);
    final f = _weights.gate(1, input, previous.hidden, Activation.sigmoid);
    final o = _weights.gate(2, input, previous.hidden, Activation.sigmoid);
    final g = _weights.gate(3, input, previous.hidden, Activation.tanh);
    final c = List.generate(
        hiddenSize, (j) => f[j] * previous.memory[j] + i[j] * g[j]);
    final t = Activation.tanh.forward(c);
    final h = List.generate(hiddenSize, (j) => o[j] * t[j]);
    return RecurrentStep(RecurrentState(h, c),
        _Cache(List.of(input), previous, [i, f, o, g, t]));
  }

  @override
  RecurrentDerivatives backward(RecurrentStep step, RecurrentState upstream) {
    final cache = step.cache as _Cache;
    final i = cache.gates[0],
        f = cache.gates[1],
        o = cache.gates[2],
        g = cache.gates[3],
        t = cache.gates[4];
    final dc = List.generate(
        hiddenSize,
        (j) =>
            upstream.memory[j] + upstream.hidden[j] * o[j] * (1 - t[j] * t[j]));
    final di =
        List.generate(hiddenSize, (j) => dc[j] * g[j] * i[j] * (1 - i[j]));
    final df = List.generate(hiddenSize,
        (j) => dc[j] * cache.previous.memory[j] * f[j] * (1 - f[j]));
    final doGate = List.generate(
        hiddenSize, (j) => upstream.hidden[j] * t[j] * o[j] * (1 - o[j]));
    final dg =
        List.generate(hiddenSize, (j) => dc[j] * i[j] * (1 - g[j] * g[j]));
    final dp = List<double>.filled(parameterCount, 0),
        dx = List<double>.filled(inputSize, 0),
        dh = List<double>.filled(hiddenSize, 0);
    final deltas = [di, df, doGate, dg];
    for (var gate = 0; gate < 4; gate++) {
      _weights.accumulate(
          gate, cache.input, cache.previous.hidden, deltas[gate], dp, dx, dh);
    }
    return RecurrentDerivatives(dp, dx,
        RecurrentState(dh, List.generate(hiddenSize, (j) => dc[j] * f[j])));
  }
}

class _Cache extends CellCache {
  final List<double> input;
  final RecurrentState previous;
  final List<List<double>> gates;
  _Cache(this.input, this.previous, this.gates);
}

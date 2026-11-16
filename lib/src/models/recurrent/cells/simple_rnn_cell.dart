import '../../../activations/activation.dart';
import '../recurrent_cell.dart';
import '../recurrent_state.dart';
import '../recurrent_step.dart';
import '../recurrent_derivatives.dart';
import 'cell_weights.dart';

/// Elman tanh cell: h = tanh(Wx + Uh_previous + b).
class SimpleRnnCell implements RecurrentCell {
  final CellWeights _weights;
  SimpleRnnCell({required int inputSize, required int hiddenSize, int? seed})
      : _weights = CellWeights(inputSize, hiddenSize, 1, seed);
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
    final h = _weights.gate(0, input, previous.hidden, Activation.tanh);
    return RecurrentStep(RecurrentState(h, List.filled(hiddenSize, 0)),
        _Cache(List.of(input), previous, h));
  }

  @override
  RecurrentDerivatives backward(RecurrentStep step, RecurrentState upstream) {
    final cache = step.cache as _Cache;
    final delta = Activation.tanh.backward(cache.output, upstream.hidden);
    final dp = List<double>.filled(parameterCount, 0),
        dx = List<double>.filled(inputSize, 0),
        dh = List<double>.filled(hiddenSize, 0);
    _weights.accumulate(
        0, cache.input, cache.previous.hidden, delta, dp, dx, dh);
    return RecurrentDerivatives(
        dp, dx, RecurrentState(dh, List.filled(hiddenSize, 0)));
  }
}

class _Cache extends CellCache {
  final List<double> input, output;
  final RecurrentState previous;
  _Cache(this.input, this.previous, this.output);
}

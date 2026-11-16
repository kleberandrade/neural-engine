/// Immutable state; memory is the LSTM cell state (zero for RNN/GRU).
class RecurrentState {
  final List<double> hidden;
  final List<double> memory;
  RecurrentState(List<double> hidden, List<double> memory)
      : hidden = List.unmodifiable(hidden),
        memory = List.unmodifiable(memory) {
    if (hidden.isEmpty ||
        hidden.length != memory.length ||
        [...hidden, ...memory].any((v) => !v.isFinite)) {
      throw ArgumentError(
          'State vectors must have matching positive finite dimensions.');
    }
  }
  factory RecurrentState.zeros(int size) =>
      RecurrentState(List.filled(size, 0), List.filled(size, 0));
}

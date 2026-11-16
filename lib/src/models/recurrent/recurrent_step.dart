import 'recurrent_state.dart';

/// Per-step cache is supplied by the cell, never stored as cross-call model state.
abstract class CellCache {
  const CellCache();
}

class RecurrentStep {
  final RecurrentState state;
  final CellCache cache;
  const RecurrentStep(this.state, this.cache);
}

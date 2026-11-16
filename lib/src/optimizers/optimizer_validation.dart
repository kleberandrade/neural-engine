void validateLearningRate(double v) {
  if (!v.isFinite || v <= 0) {
    throw ArgumentError('Learning rate must be finite and positive.');
  }
}

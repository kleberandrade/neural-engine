void validateLossVectors(List<double> p, List<double> t) {
  if (p.isEmpty ||
      p.length != t.length ||
      [...p, ...t].any((x) => !x.isFinite)) {
    throw ArgumentError(
      'Predictions and targets must have matching finite values.',
    );
  }
}

void checkProbabilities(List<double> p, List<double> t) {
  validateLossVectors(p, t);
  if ([...p, ...t].any((v) => v < 0 || v > 1)) {
    throw ArgumentError('Probabilities and targets must be in [0, 1].');
  }
}

void checkCategorical(List<double> p, List<double> t) {
  checkProbabilities(p, t);
  if ((p.reduce((a, b) => a + b) - 1).abs() > 1e-9 ||
      (t.reduce((a, b) => a + b) - 1).abs() > 1e-9) {
    throw ArgumentError('Categorical distributions must sum to 1.');
  }
}

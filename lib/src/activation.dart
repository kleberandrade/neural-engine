import 'dart:math' as math;

/// Built-in dense layer activation functions.
enum Activation {
  linear,
  sigmoid,
  tanh,
  relu,
  softmax;

  /// Applies this activation to a complete layer (softmax needs all logits).
  List<double> forward(List<double> logits) {
    if (logits.isEmpty || logits.any((v) => !v.isFinite)) {
      throw ArgumentError('Logits must be nonempty and finite.');
    }
    if (this == softmax) {
      final max = logits.reduce(math.max);
      final exps = logits.map((x) => math.exp(x - max)).toList();
      final total = exps.reduce((a, b) => a + b);
      return exps.map((x) => x / total).toList();
    }
    return logits.map((x) {
      switch (this) {
        case linear:
          return x;
        case sigmoid:
          if (x >= 0) return 1 / (1 + math.exp(-x));
          final e = math.exp(x);
          return e / (1 + e);
        case tanh:
          final e = math.exp(-2 * x.abs());
          return (x < 0 ? -1 : 1) * (1 - e) / (1 + e);
        case relu:
          return math.max(0.0, x);
        case softmax:
          throw StateError('Handled above.');
      }
    }).toList();
  }

  /// Multiplies the activation Jacobian transpose by an upstream gradient.
  List<double> backward(List<double> output, List<double> upstream) {
    if (output.isEmpty ||
        output.length != upstream.length ||
        [...output, ...upstream].any((x) => !x.isFinite)) {
      throw ArgumentError(
        'Activation gradients must have matching finite values.',
      );
    }
    final dot = this == softmax
        ? List.generate(
            output.length,
            (i) => output[i] * upstream[i],
          ).reduce((a, b) => a + b)
        : 0.0;
    return List.generate(output.length, (i) {
      final y = output[i];
      switch (this) {
        case linear:
          return upstream[i];
        case sigmoid:
          return upstream[i] * y * (1 - y);
        case tanh:
          return upstream[i] * (1 - y * y);
        case relu:
          return y > 0 ? upstream[i] : 0.0;
        case softmax:
          return y * (upstream[i] - dot);
      }
    });
  }
}

/// Immutable specification; weights belong to each network, not this object.
class Dense {
  final int units;
  final Activation activation;

  Dense(this.units, {this.activation = Activation.linear}) {
    if (units <= 0) {
      throw ArgumentError.value(units, 'units', 'Must be positive.');
    }
  }
}

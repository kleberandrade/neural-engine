class DensePass {
  final List<List<double>> outputs;
  final List<List<double>> logits;
  DensePass(this.outputs, this.logits);
}

class DenseDerivatives {
  final List<double> parameters;
  final List<double> input;
  DenseDerivatives(this.parameters, this.input);
}

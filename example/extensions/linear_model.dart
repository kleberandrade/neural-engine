import 'package:neural_engine/neural_engine.dart';

/// External model: a*x+b, intentionally not a NeuralNetwork subclass.
class LinearModel implements DifferentiableModel<List<double>>, JsonModel {
  List<double> _parameters = [0, 0];
  @override
  int get parameterCount => 2;
  @override
  List<double> get parameters => List.unmodifiable(_parameters);
  @override
  set parameters(List<double> values) {
    if (values.length != 2 || values.any((v) => !v.isFinite)) {
      throw ArgumentError('Expected two finite parameters.');
    }
    _parameters = List.of(values);
  }

  LinearModel();
  factory LinearModel.fromJson(Map<String, dynamic> json) {
    if (json['format'] != 'example_linear' || json['version'] != 1) {
      throw const FormatException('Invalid linear model format.');
    }
    return LinearModel()
      ..parameters = (json['parameters'] as List<dynamic>)
          .map((v) => (v as num).toDouble())
          .toList();
  }
  @override
  List<double> predict(List<double> input) {
    if (input.length != 1 || !input.single.isFinite) {
      throw ArgumentError('Expected one finite feature.');
    }
    return List.unmodifiable([_parameters[0] * input.single + _parameters[1]]);
  }

  @override
  List<double> gradients(
      {required List<double> input,
      required List<double> target,
      required Loss loss}) {
    final d = loss.gradient(predict(input), target).single;
    return [d * input.single, d];
  }

  @override
  double evaluate(
      {required List<List<double>> inputs,
      required List<List<double>> targets,
      required Loss loss}) {
    if (inputs.isEmpty || inputs.length != targets.length) {
      throw ArgumentError('Expected matching nonempty data.');
    }
    var sum = 0.0;
    for (var i = 0; i < inputs.length; i++) {
      sum += loss.value(predict(inputs[i]), targets[i]) / inputs.length;
    }
    return sum;
  }

  @override
  Map<String, Object?> toJson() =>
      {'format': 'example_linear', 'version': 1, 'parameters': parameters};
}

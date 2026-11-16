import 'recurrent_state.dart';

class RecurrentDerivatives {
  final List<double> parameters;
  final List<double> input;
  final RecurrentState previous;
  RecurrentDerivatives(
      List<double> parameters, List<double> input, this.previous)
      : parameters = List.unmodifiable(parameters),
        input = List.unmodifiable(input);
}

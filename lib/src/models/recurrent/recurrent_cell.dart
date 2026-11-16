import '../../contracts/parameterized_model.dart';
import 'recurrent_state.dart';
import 'recurrent_step.dart';
import 'recurrent_derivatives.dart';

/// A differentiable recurrent transition; owns weights, not inference sessions.
abstract interface class RecurrentCell implements ParameterizedModel {
  int get inputSize;
  int get hiddenSize;
  RecurrentStep forward(List<double> input, RecurrentState previous);
  RecurrentDerivatives backward(RecurrentStep step, RecurrentState upstream);
}

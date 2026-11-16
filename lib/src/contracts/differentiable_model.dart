import 'predictor.dart';
import 'parameterized_model.dart';
import '../losses/loss.dart';

/// A supervised model usable by a trainer independently of its input shape.
abstract interface class DifferentiableModel<I>
    implements Predictor<I>, ParameterizedModel {
  List<double> gradients(
      {required I input, required List<double> target, required Loss loss});
  double evaluate(
      {required List<I> inputs,
      required List<List<double>> targets,
      required Loss loss});
}

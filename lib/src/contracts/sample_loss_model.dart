import '../losses/loss.dart';

/// Optional incremental-evaluation contract. Dataset loss must be the arithmetic
/// mean of these finite per-sample losses, added in input order, divided once.
/// Models with a different reduction should keep their existing evaluate method.
abstract interface class SampleLossModel<I> {
  double sampleLoss(
      {required I input, required List<double> target, required Loss loss});
}

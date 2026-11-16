import '../contracts/json_model.dart';
import 'optimizer.dart';

/// Optional extension: serializable configuration and explicit state restoration.
/// Custom optimizers can supply their own checkpoint decoder to TrainingSession.
abstract interface class CheckpointOptimizer implements Optimizer, JsonModel {
  CheckpointOptimizerState restoreState(
      Map<String, dynamic> json, int parameterCount);
}

abstract interface class CheckpointOptimizerState
    implements OptimizerState, JsonModel {}

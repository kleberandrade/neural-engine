import '../../persistence/training_checkpoint.dart';
import '../training_history.dart';

/// A resumable snapshot, including optimizer moments and absolute shuffle seed.
class AsyncTrainingResult {
  final TrainingCheckpoint checkpoint;
  final TrainingHistory history;
  final bool cancelled;
  final Duration elapsed;
  const AsyncTrainingResult(
      {required this.checkpoint,
      required this.history,
      required this.cancelled,
      required this.elapsed});
}

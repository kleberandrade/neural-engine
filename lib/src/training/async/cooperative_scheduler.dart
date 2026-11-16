import '../training_step.dart';

/// A work-duration budget is checked between indivisible executor steps. It is
/// not a real-time deadline and cannot interrupt one sample, batch or chunk.
class CooperativeScheduler {
  final int batchesPerYield;
  final Duration? maxWorkDuration;
  final _clock = Stopwatch()..start();
  int _batches = 0;
  CooperativeScheduler(this.batchesPerYield, this.maxWorkDuration);
  bool shouldYield(TrainingStep step) {
    if (step.phase == TrainingPhase.batchUpdate) _batches++;
    return step.isEvaluation ||
        step.phase == TrainingPhase.epochComplete ||
        _batches >= batchesPerYield ||
        (maxWorkDuration != null && _clock.elapsed >= maxWorkDuration!);
  }

  Future<void> yieldNow() async {
    await Future<void>.delayed(Duration.zero);
    _batches = 0;
    _clock.reset();
  }
}

import 'evaluation_progress.dart';
import 'dart:async';
import 'async_training_request.dart';
import 'async_training_result.dart';
import 'training_cancellation.dart';
import 'training_progress.dart';
import 'worker_codec.dart';
import 'worker_web.dart' if (dart.library.io) 'worker_native.dart' as platform;

/// Automatic selects an isolate on native Dart and cooperative batches on web.
enum TrainingExecution { automatic, cooperative, isolate }

/// An owned worker lifecycle: subscribe immediately, await result, cancel safely.
/// Cancelling a progress subscription does not cancel training; call [cancel].
class AsyncTrainingTask {
  final _evaluation = StreamController<EvaluationProgress>.broadcast();
  Stream<EvaluationProgress> get evaluationProgress => _evaluation.stream;
  final _cancellation = TrainingCancellation();
  final _progress = StreamController<TrainingProgress>.broadcast();
  late final Future<AsyncTrainingResult> result;
  final TrainingExecution execution;
  Stream<TrainingProgress> get progress => _progress.stream;

  AsyncTrainingTask.start(AsyncTrainingRequest request,
      {TrainingExecution execution = TrainingExecution.automatic})
      : execution = execution == TrainingExecution.automatic
            ? (platform.supportsIsolates
                ? TrainingExecution.isolate
                : TrainingExecution.cooperative)
            : execution {
    result = _run(request);
  }

  void cancel() => _cancellation.cancel();

  Future<AsyncTrainingResult> _run(AsyncTrainingRequest request) async {
    try {
      // Let the caller attach listeners (including for pre-start cancellation).
      await Future<void>.delayed(Duration.zero);
      return await (execution == TrainingExecution.isolate
          ? platform.runInIsolate(request, _cancellation, _progress.add,
              onEvaluationProgress: _evaluation.add)
          : runCooperatively(request, _cancellation, _progress.add,
              onEvaluationProgress: _evaluation.add));
    } finally {
      // Do not await close: a paused listener must not prevent result completion.
      unawaited(_progress.close());
      unawaited(_evaluation.close());
    }
  }
}

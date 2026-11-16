import 'evaluation_progress.dart';
import 'async_training_request.dart';
import 'async_training_result.dart';
import 'training_cancellation.dart';
import 'training_progress.dart';

const supportsIsolates = false;
Future<AsyncTrainingResult> runInIsolate(
        AsyncTrainingRequest request,
        TrainingCancellation cancellation,
        void Function(TrainingProgress) progress,
        {void Function(EvaluationProgress)? onEvaluationProgress}) =>
    Future.error(UnsupportedError(
        'Isolate execution is unavailable on this platform. Use automatic or cooperative.'));

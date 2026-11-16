import 'evaluation_progress.dart';
import 'dart:async';
import 'dart:isolate';
import 'async_training_request.dart';
import 'async_training_result.dart';
import 'training_cancellation.dart';
import 'training_progress.dart';
import 'worker_codec.dart';
import 'worker_error.dart';

const supportsIsolates = true;

Future<AsyncTrainingResult> runInIsolate(AsyncTrainingRequest request,
    TrainingCancellation cancellation, void Function(TrainingProgress) progress,
    {void Function(EvaluationProgress)? onEvaluationProgress}) async {
  final receive = ReceivePort();
  final result = Completer<AsyncTrainingResult>();
  SendPort? control;
  final removeCancel = cancellation.onCancel(() => control?.send('cancel'));
  final subscription = receive.listen((dynamic message) {
    if (result.isCompleted) return;
    if (message is SendPort) {
      control = message;
      if (cancellation.isCancelled) control!.send('cancel');
    } else if (message is Map<String, dynamic>) {
      switch (message['type']) {
        case 'progress':
          progress(decodeProgress(message['data'] as Map<String, dynamic>));
        case 'evaluation':
          onEvaluationProgress
              ?.call(decodeEvaluation(message['data'] as Map<String, dynamic>));
        case 'result':
          result
              .complete(decodeResult(message['data'] as Map<String, dynamic>));
        case 'error':
          result.completeError(TrainingWorkerException(
              message['error'] as String, message['stack'] as String));
      }
    } else {
      final description = message is List
          ? message.join('\n')
          : 'Worker exited without a result.';
      result.completeError(TrainingWorkerException(description, ''));
    }
  });
  Isolate? isolate;
  try {
    isolate = await Isolate.spawn(_worker,
        <Object>[receive.sendPort, request.toJson(), cancellation.isCancelled],
        onError: receive.sendPort,
        onExit: receive.sendPort,
        errorsAreFatal: true);
    return await result.future;
  } finally {
    removeCancel();
    isolate?.kill(priority: Isolate.immediate);
    await subscription.cancel();
    receive.close();
  }
}

// Top-level entry point avoids capturing a UI/model object graph in a closure.
Future<void> _worker(List<Object> arguments) async {
  final output = arguments[0] as SendPort;
  final control = ReceivePort();
  final cancellation = TrainingCancellation();
  if (arguments[2] as bool) cancellation.cancel();
  final subscription = control.listen((dynamic message) {
    if (message == 'cancel') cancellation.cancel();
  });
  output.send(control.sendPort);
  try {
    final result = await runCooperatively(
        AsyncTrainingRequest.fromJson(arguments[1] as Map<String, dynamic>),
        cancellation,
        (p) => output.send({'type': 'progress', 'data': encodeProgress(p)}),
        onEvaluationProgress: (p) =>
            output.send({'type': 'evaluation', 'data': encodeEvaluation(p)}));
    output.send({'type': 'result', 'data': encodeResult(result)});
  } catch (error, stack) {
    output.send({'type': 'error', 'error': '$error', 'stack': '$stack'});
  } finally {
    await subscription.cancel();
    control.close();
  }
}

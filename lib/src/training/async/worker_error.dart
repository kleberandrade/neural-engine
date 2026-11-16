/// Worker failures carry a remote message and stack; they produce no checkpoint.
class TrainingWorkerException implements Exception {
  final String message;
  final String remoteStack;
  const TrainingWorkerException(this.message, this.remoteStack);
  @override
  String toString() => 'TrainingWorkerException: $message';
}

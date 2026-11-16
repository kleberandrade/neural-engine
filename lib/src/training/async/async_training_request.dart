import 'dart:convert';
import '../../persistence/training_checkpoint.dart';
import '../../tensors/image_tensor.dart';

/// Serializable built-in loss for a portable worker. Custom losses use fitAsync.
enum TrainingLoss {
  meanSquaredError,
  binaryCrossEntropy,
  categoricalCrossEntropy
}

/// Immutable worker input. Models, optimizer state and datasets are copied;
/// workers never mutate the caller's model. Use the result checkpoint to restore.
class AsyncTrainingRequest {
  final String _json;

  AsyncTrainingRequest._(Map<String, dynamic> data) : _json = jsonEncode(data) {
    if ((data['epochs'] as int) <= 0 ||
        (data['batchSize'] as int) <= 0 ||
        (data['batchesPerYield'] as int) <= 0) {
      throw ArgumentError(
          'Epochs, batch size and batches per yield must be positive.');
    }
    final chunk = data['evaluationSamplesPerYield'] ?? 32;
    final budget = data['maxWorkMicroseconds'];
    if (chunk is! int ||
        chunk <= 0 ||
        (budget != null && (budget is! int || budget <= 0))) {
      throw ArgumentError(
          'Evaluation chunk and optional work budget must be positive integers.');
    }
    final norm = data['maxGradientNorm'] as double?;
    if (norm != null && (!norm.isFinite || norm <= 0)) {
      throw ArgumentError('Gradient norm must be finite and positive.');
    }
    if ((data['validationInputs'] == null) !=
        (data['validationTargets'] == null)) {
      throw ArgumentError(
          'Validation inputs and targets must be provided together.');
    }
  }

  /// Inputs: vectors for MLP, sequences of vectors for RNN/LSTM/GRU, or
  /// ImageTensor objects for CNN. Only built-in model/optimizer codecs are used.
  factory AsyncTrainingRequest({
    required TrainingCheckpoint checkpoint,
    required List<Object> inputs,
    required List<List<double>> targets,
    required TrainingLoss loss,
    int epochs = 1,
    int batchSize = 32,
    bool shuffle = true,
    double? maxGradientNorm,
    List<Object>? validationInputs,
    List<List<double>>? validationTargets,
    int batchesPerYield = 1,
    int evaluationSamplesPerYield = 32,
    Duration? maxWorkDuration,
  }) {
    Object encodeInput(Object input) => input is ImageTensor
        ? {
            'height': input.height,
            'width': input.width,
            'channels': input.channels,
            'values': input.values
          }
        : input;
    return AsyncTrainingRequest._({
      'checkpoint': checkpoint.toJson(),
      'inputs': inputs.map(encodeInput).toList(),
      'targets': targets,
      'loss': loss.name,
      'epochs': epochs,
      'batchSize': batchSize,
      'shuffle': shuffle,
      'maxGradientNorm': maxGradientNorm,
      'batchesPerYield': batchesPerYield,
      'evaluationSamplesPerYield': evaluationSamplesPerYield,
      'maxWorkMicroseconds': maxWorkDuration?.inMicroseconds,
      'validationInputs': validationInputs?.map(encodeInput).toList(),
      'validationTargets': validationTargets,
    });
  }

  /// For platform transport; values are validated again by model/loss decoders.
  factory AsyncTrainingRequest.fromJson(Map<String, dynamic> json) =>
      AsyncTrainingRequest._(json);
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
}

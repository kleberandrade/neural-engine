import '../../contracts/differentiable_model.dart';
import '../../losses/loss.dart';
import '../../losses/mean_squared_error.dart';
import '../../losses/binary_cross_entropy.dart';
import '../../losses/categorical_cross_entropy.dart';
import '../../models/dense/neural_network.dart';
import '../../models/cnn/convolutional_network.dart';
import '../../models/recurrent/recurrent_network.dart';
import '../../persistence/training_checkpoint.dart';
import '../../tensors/image_tensor.dart';
import '../training_history.dart';
import '../training_session.dart';
import 'async_training_request.dart';
import 'async_training_result.dart';
import 'training_cancellation.dart';
import 'training_progress.dart';

Future<AsyncTrainingResult> runCooperatively(
    AsyncTrainingRequest request,
    TrainingCancellation cancellation,
    void Function(TrainingProgress) progress) {
  final json = request.toJson();
  final checkpoint =
      TrainingCheckpoint.fromJson(json['checkpoint'] as Map<String, dynamic>);
  final loss = switch (TrainingLoss.values.byName(json['loss'] as String)) {
    TrainingLoss.meanSquaredError => const MeanSquaredError(),
    TrainingLoss.binaryCrossEntropy => const BinaryCrossEntropy(),
    TrainingLoss.categoricalCrossEntropy => const CategoricalCrossEntropy(),
  };
  return switch (checkpoint.model['format']) {
    'neural_engine' => _run<List<double>>(
        json,
        checkpoint,
        loss,
        NeuralNetwork.fromJson,
        (value) => _vector(value),
        cancellation,
        progress),
    'neural_engine_recurrent' => _run<List<List<double>>>(
        json,
        checkpoint,
        loss,
        RecurrentNetwork.fromJson,
        (value) => (value as List).map(_vector).toList(),
        cancellation,
        progress),
    'neural_engine_cnn' => _run<ImageTensor>(
          json, checkpoint, loss, ConvolutionalNetwork.fromJson, (value) {
        final tensor = value as Map<String, dynamic>;
        return ImageTensor(
            height: tensor['height'] as int,
            width: tensor['width'] as int,
            channels: tensor['channels'] as int,
            values: _vector(tensor['values']));
      }, cancellation, progress),
    _ => throw UnsupportedError(
        'Worker supports MLP, CNN, RNN, LSTM and GRU checkpoints.'),
  };
}

List<double> _vector(Object? value) =>
    (value as List).map((v) => (v as num).toDouble()).toList();

Future<AsyncTrainingResult> _run<I>(
    Map<String, dynamic> json,
    TrainingCheckpoint checkpoint,
    Loss loss,
    DifferentiableModel<I> Function(Map<String, dynamic>) decoder,
    I Function(Object?) inputDecoder,
    TrainingCancellation cancellation,
    void Function(TrainingProgress) progress) {
  final session =
      TrainingSession<I>.restore(checkpoint: checkpoint, modelDecoder: decoder);
  return session.fitAsync(
    inputs: (json['inputs'] as List).map(inputDecoder).toList(),
    targets: (json['targets'] as List).map(_vector).toList(),
    loss: loss,
    validationInputs:
        (json['validationInputs'] as List?)?.map(inputDecoder).toList(),
    validationTargets:
        (json['validationTargets'] as List?)?.map(_vector).toList(),
    epochs: json['epochs'] as int,
    batchSize: json['batchSize'] as int,
    shuffle: json['shuffle'] as bool,
    maxGradientNorm: json['maxGradientNorm'] as double?,
    batchesPerYield: json['batchesPerYield'] as int,
    cancellation: cancellation,
    onProgress: progress,
  );
}

Map<String, Object?> encodeProgress(TrainingProgress p) => {
      'completed': p.epochsCompleted,
      'requested': p.requestedEpochs,
      'run': p.epochsThisRun,
      'loss': p.loss,
      'validation': p.validationLoss,
      'elapsed': p.elapsed.inMicroseconds,
    };
TrainingProgress decodeProgress(Map<String, dynamic> json) => TrainingProgress(
      epochsCompleted: json['completed'] as int,
      requestedEpochs: json['requested'] as int,
      epochsThisRun: json['run'] as int,
      loss: (json['loss'] as num).toDouble(),
      validationLoss: (json['validation'] as num?)?.toDouble(),
      elapsed: Duration(microseconds: json['elapsed'] as int),
    );
Map<String, Object?> encodeResult(AsyncTrainingResult result) => {
      'checkpoint': result.checkpoint.toJson(),
      'losses': result.history.losses,
      'validation': result.history.validationLosses,
      'cancelled': result.cancelled,
      'elapsed': result.elapsed.inMicroseconds,
    };
AsyncTrainingResult decodeResult(Map<String, dynamic> json) =>
    AsyncTrainingResult(
      checkpoint: TrainingCheckpoint.fromJson(
          json['checkpoint'] as Map<String, dynamic>),
      history: TrainingHistory(
          _vector(json['losses']), _vector(json['validation']),
          stoppedEarly: false, bestEpoch: null),
      cancelled: json['cancelled'] as bool,
      elapsed: Duration(microseconds: json['elapsed'] as int),
    );

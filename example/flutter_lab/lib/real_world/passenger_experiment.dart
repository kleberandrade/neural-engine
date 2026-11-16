import 'package:neural_engine/neural_engine.dart';
import 'passenger_dataset.dart';
import 'real_world_experiment.dart';

class PassengerExperiment implements RealWorldExperiment {
  final data = PassengerDataset();
  final int epochs;
  PassengerExperiment({this.epochs = 100});
  @override
  String get name => 'AirPassengers';
  @override
  AsyncTrainingRequest request() {
    final session = TrainingSession<List<List<double>>>(
        model: RecurrentNetwork(
            inputSize: 1,
            hiddenSize: 8,
            outputSize: 1,
            kind: RecurrentKind.gru,
            seed: 42),
        optimizer: Adam(learningRate: 0.01),
        seed: 42);
    return AsyncTrainingRequest(
        checkpoint: session.checkpoint(),
        inputs: data.train.inputs,
        targets: data.train.targets,
        validationInputs: data.validation.inputs,
        validationTargets: data.validation.targets,
        loss: TrainingLoss.meanSquaredError,
        epochs: epochs,
        batchSize: 12,
        maxGradientNorm: 1,
        shuffle: false);
  }

  @override
  Map<String, Object?> report(AsyncTrainingResult result) {
    if (result.cancelled) {
      throw StateError('A cancelled experiment has no test report.');
    }
    final model = RecurrentNetwork.fromJson(result.checkpoint.model);
    final predicted = data.test.inputs
        .map((x) => data.unscale(model.predict(x).single))
        .toList();
    final actual = data.test.ids.map((id) => data.values[id]).toList();
    final seasonal = data.test.ids.map((id) => data.values[id - 12]).toList();
    final persistence = data.test.ids.map((id) => data.values[id - 1]).toList();
    final metric = RegressionMetrics(targets: actual, predictions: predicted);
    return {
      'dataset': name,
      'trainTargets': data.train.ids.length,
      'validationTargets': data.validation.ids.length,
      'testTargets': data.test.ids.length,
      'trainEnd': '1956-12',
      'validationEnd': '1958-12',
      'testEnd': '1960-12',
      'lookback': PassengerDataset.lookback,
      'epochs': result.checkpoint.epochsCompleted,
      'loss': result.history.losses.last,
      'validationLoss': result.history.validationLosses.last,
      'testMAEThousands': metric.mae,
      'testRMSEThousands': metric.rmse,
      'seasonalMAEThousands':
          RegressionMetrics(targets: actual, predictions: seasonal).mae,
      'persistenceMAEThousands':
          RegressionMetrics(targets: actual, predictions: persistence).mae,
      'scaler': data.scaler.toJson(),
      'milliseconds': result.elapsed.inMilliseconds,
      'sampleRows': [
        for (var i = 0; i < actual.length; i++)
          {
            'month': data.months[data.test.ids[i]],
            'actual': actual[i],
            'prediction': predicted[i],
            'seasonal': seasonal[i]
          }
      ],
      'protocol':
          'Chronological targets, 12 observed monthly lags, log + training-only scaler, rolling one-step forecast; not a recursive 24-month forecast. Fixed recipe; no test tuning.'
    };
  }
}

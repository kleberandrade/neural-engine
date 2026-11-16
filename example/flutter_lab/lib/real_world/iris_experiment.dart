import 'package:neural_engine/neural_engine.dart';
import 'iris_dataset.dart';
import 'real_world_experiment.dart';

class IrisExperiment implements RealWorldExperiment {
  final data = IrisDataset();
  final int epochs;
  IrisExperiment({this.epochs = 120});
  @override
  String get name => 'Iris';
  @override
  AsyncTrainingRequest request() {
    final session = TrainingSession<List<double>>(
        model: NeuralNetwork(inputSize: 4, seed: 42, layers: [
          Dense(8, activation: Activation.tanh),
          Dense(3, activation: Activation.softmax)
        ]),
        optimizer: Adam(learningRate: 0.01),
        seed: 42);
    return AsyncTrainingRequest(
        checkpoint: session.checkpoint(),
        inputs: data.train.inputs,
        targets: data.train.targets,
        validationInputs: data.validation.inputs,
        validationTargets: data.validation.targets,
        loss: TrainingLoss.categoricalCrossEntropy,
        epochs: epochs,
        batchSize: 16,
        maxGradientNorm: 1);
  }

  @override
  Map<String, Object?> report(AsyncTrainingResult result) {
    if (result.cancelled) {
      throw StateError('A cancelled experiment has no test report.');
    }
    final model = NeuralNetwork.fromJson(result.checkpoint.model);
    final actual = data.test.targets.map(predictedClass).toList();
    final predicted =
        data.test.inputs.map((x) => predictedClass(model.predict(x))).toList();
    final metric = ClassificationMetrics.fromLabels(
        targets: actual, predictions: predicted, classCount: 3);
    final counts = List<int>.filled(3, 0);
    for (final target in data.train.targets) {
      counts[predictedClass(target)]++;
    }
    final majority = counts.indexOf(counts.reduce((a, b) => a > b ? a : b));
    final baseline = ClassificationMetrics.fromLabels(
        targets: actual,
        predictions: List.filled(actual.length, majority),
        classCount: 3);
    return {
      'dataset': name,
      'sourceRows': 150,
      'uniqueRows': data.uniqueRows,
      'train': data.train.ids.length,
      'validation': data.validation.ids.length,
      'test': data.test.ids.length,
      'epochs': result.checkpoint.epochsCompleted,
      'loss': result.history.losses.last,
      'validationLoss': result.history.validationLosses.last,
      'testAccuracy': metric.accuracy,
      'testMacroF1': metric.macroF1,
      'confusionMatrix': metric.confusionMatrix,
      'baselineAccuracy': baseline.accuracy,
      'scaler': data.scaler.toJson(),
      'milliseconds': result.elapsed.inMilliseconds,
      'sampleRows': [
        for (var i = 0; i < actual.length; i++)
          {
            'id': data.test.ids[i],
            'actual': IrisDataset.labels[actual[i]],
            'prediction': IrisDataset.labels[predicted[i]]
          }
      ],
      'protocol':
          'Exact-row deduplication, seeded stratified 60/20/remainder split; scaler fit on training only; fixed recipe, test not used for selection.'
    };
  }
}

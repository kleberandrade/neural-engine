import 'package:neural_engine/neural_engine.dart';
import '../data/sequence_dataset.dart';

List<Map<String, Object>> trainSequences(int epochs) {
  final train = sequenceDataset();
  final test = sequenceDataset(test: true);
  return [
    for (final kind in RecurrentKind.values) _train(kind, epochs, train, test)
  ];
}

Map<String, Object> _train(
    RecurrentKind kind,
    int epochs,
    ({List<List<List<double>>> inputs, List<List<double>> targets}) train,
    ({List<List<List<double>>> inputs, List<List<double>> targets}) test) {
  final model = RecurrentNetwork(
      inputSize: 1, hiddenSize: 6, outputSize: 1, kind: kind, seed: 42);
  final timer = Stopwatch()..start();
  final history = model.fit(
      inputs: train.inputs,
      targets: train.targets,
      loss: const MeanSquaredError(),
      optimizer: Adam(learningRate: 0.015),
      epochs: epochs,
      batchSize: 8,
      maxGradientNorm: 1);
  timer.stop();
  final predictions = test.inputs.map((x) => model.predict(x).single).toList();
  final targets = test.targets.map((x) => x.single).toList();
  final metric = RegressionMetrics(targets: targets, predictions: predictions);
  return {
    'kind': kind.name,
    'parameters': model.parameterCount,
    'milliseconds': timer.elapsedMilliseconds,
    'mse': metric.mse,
    'mae': metric.mae,
    'losses': history.losses,
    'targets': targets,
    'predictions': predictions,
    'input': test.inputs.first.map((x) => x.single).toList(),
    'hidden': model.trace(test.inputs.first).expand((s) => s.hidden).toList(),
    'memory': model.trace(test.inputs.first).expand((s) => s.memory).toList()
  };
}

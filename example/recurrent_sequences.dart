import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
// Pure Dart shared example fixture; the file does not import Flutter.
// ignore: avoid_relative_lib_imports
import 'flutter_lab/lib/sequence_dataset.dart';

void main() {
  final train = sequenceDataset();
  final test = sequenceDataset(test: true);
  for (final kind in RecurrentKind.values) {
    final model = RecurrentNetwork(
        inputSize: 1, hiddenSize: 6, outputSize: 1, kind: kind, seed: 42);
    final watch = Stopwatch()..start();
    final history = model.fit(
        inputs: train.inputs,
        targets: train.targets,
        loss: const MeanSquaredError(),
        optimizer: Adam(learningRate: 0.015),
        epochs: 180,
        batchSize: 8,
        maxGradientNorm: 1);
    watch.stop();
    final predictions =
        test.inputs.map((x) => model.predict(x).single).toList();
    final report = RegressionMetrics(
        targets: test.targets.map((x) => x.single).toList(),
        predictions: predictions);
    print(
        '${kind.name}: parameters=${model.parameterCount}, epochs=${history.epochs}, MSE=${report.mse}, MAE=${report.mae}, ms=${watch.elapsedMilliseconds}');
    final restored = RecurrentNetwork.fromJson(
        jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>);
    if (report.mse > 0.01 ||
        restored.predict(test.inputs.first).single != predictions.first) {
      throw StateError('${kind.name} sequence learning/roundtrip failed.');
    }
  }
}

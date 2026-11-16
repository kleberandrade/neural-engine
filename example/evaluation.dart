import 'package:neural_engine/neural_engine.dart';

void main() {
  final training = <List<double>>[
    [10],
    [20],
    [30],
    [40]
  ];
  final targets = <List<double>>[
    [21],
    [41],
    [61],
    [81]
  ];
  // Fit both input/target transforms on training observations only.
  final inputScaler = StandardScaler.fit(training);
  final targetScaler = StandardScaler.fit(targets);
  final model = NeuralNetwork(inputSize: 1, layers: [Dense(1)], seed: 42);
  model.fit(
      inputs: training.map(inputScaler.transform).toList(),
      targets: targets.map(targetScaler.transform).toList(),
      loss: const MeanSquaredError(),
      optimizer: SGD(learningRate: 0.05),
      epochs: 150,
      batchSize: 4);
  final heldOut = <List<double>>[
    [15],
    [25],
    [35],
    [45]
  ];
  final predictions = heldOut
      .map((row) => targetScaler
          .inverseTransform(model.predict(inputScaler.transform(row)))
          .single)
      .toList();
  final metrics = RegressionMetrics(
      targets: heldOut.map((row) => 2 * row.single + 1).toList(),
      predictions: predictions);
  print('Predictions in original units: $predictions');
  print(
      'MSE=${metrics.mse}; MAE=${metrics.mae}; RMSE=${metrics.rmse}; R²=${metrics.rSquared}');
  if (metrics.rmse > 0.001) throw StateError('Scaled regression failed.');
}

# Evaluation, normalization and CNN validation

[Português](evaluation.pt-BR.md)

Preprocessing, loss and reporting are separate responsibilities. Fit scalers only
on training observations. The fitted objects are immutable and reused on
validation/test/production inputs. Save their public statistics alongside the
model in your application if deployment needs the same transform.

```dart
final scaler = StandardScaler.fit(trainingRows);
final scaledTraining = trainingRows.map(scaler.transform).toList();
final scaledValidation = validationRows.map(scaler.transform).toList();
final original = scaler.inverseTransform(scaledTraining.first);
```

StandardScaler uses population standard deviation and scale 1 for constant
features. MinMaxScaler maps training minima/maxima to 0/1 without clipping held-out
outliers. Constant dimensions use range 1. Shape mismatch/nonfinite inputs fail.

`ClassificationMetrics.fromLabels` reports accuracy, per-class precision, recall,
F1 and macro F1. Confusion matrix rows are true classes; columns are predictions.
Undefined ratios are zero. Convert sigmoid outputs using a chosen threshold, or
softmax scores with argmax, before passing labels. These reports are not training
objectives or calibration guarantees.

```dart
final report = ClassificationMetrics.fromLabels(
  targets: [0, 0, 1, 1], predictions: [0, 1, 1, 1], classCount: 2,
);
print(report.accuracy); // 0.75
print(report.confusionMatrix); // [[1, 1], [0, 2]]
final regression = RegressionMetrics(targets: [1, 2, 3], predictions: [2, 2, 2]);
print(regression.mse); // 2/3
```

RegressionMetrics also provides MAE, RMSE and R². For constant targets, R² is 1
for exact predictions and 0 otherwise. Flatten corresponding output coordinates
to report autoencoder reconstruction metrics; keep sample alignment intact.

CNN now uses the same MiniBatchTrainer lifecycle as Dense and recurrent models:

```dart
final history = cnn.fit(
  inputs: trainingImages, targets: trainingLabels,
  validationInputs: validationImages, validationTargets: validationLabels,
  loss: const CategoricalCrossEntropy(), optimizer: Adam(learningRate: 0.02),
  epochs: 100, patience: 15, minDelta: 0.0001, maxGradientNorm: 1,
);
```

The snippet assumes the prepared CNN/datasets in the CLI example. Use separate
train/validation/test splits. Patience restores the best qualifying validation
epoch; history retains all completed epochs. Test results must not select the
stopping point. See `example/cnn_bars.dart` and the shared lifecycle contract.

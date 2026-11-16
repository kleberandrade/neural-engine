# neural_engine

[![Dart CI](https://github.com/kleberandrade/neural-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/kleberandrade/neural-engine/actions/workflows/ci.yml)
[![MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Pure Dart neural networks for Flutter apps and Dart services. Train dense
feedforward networks with backpropagation, SGD or Adam, then export a versioned
JSON inference model. No runtime dependencies, Flutter imports, native bindings
or network access in the core.

[Português](README.pt-BR.md) · [Concepts and architecture](doc/architecture.md) · [Flutter lab](example/flutter_lab/README.md) · [Contributing](CONTRIBUTING.md)

**Status:** initial 0.1.0 source release; not yet published on pub.dev.

## Install from GitHub

```yaml
dependencies:
  neural_engine:
    git:
      url: https://github.com/kleberandrade/neural-engine.git
      ref: main
```

Pin a commit for reproducible applications. Dart >=3.3.0. Works in Flutter
without adding Flutter as a core dependency.

## Learn XOR

```dart
import 'package:neural_engine/neural_engine.dart';

void main() {
  final network = NeuralNetwork(
    inputSize: 2,
    layers: [
      Dense(8, activation: Activation.tanh),
      Dense(1, activation: Activation.sigmoid),
    ],
    seed: 42,
  );

  final history = network.fit(
    inputs: [[0, 0], [0, 1], [1, 0], [1, 1]],
    targets: [[0], [1], [1], [0]],
    loss: const BinaryCrossEntropy(),
    optimizer: Adam(learningRate: 0.03),
    epochs: 1200,
    batchSize: 4,
  );

  print(history.losses.last);
  print(network.predict([0, 1])); // Close to [1].
}
```

A neural network adjusts weights using labeled examples. Unlike `fuzzy_engine`,
it does not execute human-authored linguistic rules. Unlike `genetic_engine`,
its built-in training follows gradients rather than population evolution.
These packages have independent cores.

## Features

- Dense MLPs; linear, sigmoid, tanh, ReLU and softmax activations.
- MSE, binary cross entropy and categorical cross entropy.
- Stable fused sigmoid/BCE and softmax/CCE computations during training/evaluation.
- Mini-batch SGD and bias-corrected Adam; seeded initialization and shuffling.
- Post-epoch training/validation loss, early stopping with best-weight restoration.
- Versioned JSON model interchange, parameter snapshots and analytic gradients.
- Immutable layer specifications, predictions and histories; per-fit optimizer state.
- Custom `Loss` and `Optimizer` interfaces.

| Task | Output activation | Loss | Target |
| --- | --- | --- | --- |
| Regression | linear | `MeanSquaredError` | Numeric vector |
| Binary / multilabel classification | sigmoid | `BinaryCrossEntropy` | Each value in [0, 1] |
| Exclusive multiclass classification | softmax | `CategoricalCrossEntropy` | Distribution summing to 1 |

MSE and BCE average over output coordinates, then over samples. Categorical
cross entropy sums over classes, then averages over samples. BCE requires a
sigmoid output and CCE requires softmax. Hidden softmax layers are supported
with the full Jacobian-vector product.

## Validation and early stopping

```dart
final history = network.fit(
  inputs: trainingInputs,
  targets: trainingTargets,
  validationInputs: validationInputs,
  validationTargets: validationTargets,
  loss: const BinaryCrossEntropy(),
  optimizer: Adam(),
  epochs: 1000,
  patience: 20,
  minDelta: 0.0001,
);
```

This snippet assumes an existing sigmoid-output network and prepared datasets.
Supply both validation arrays. `patience` requires validation data. An improvement
must exceed `minDelta`; with patience enabled the best qualifying epoch is
restored at the end, including when the epoch limit is reached. History still
records all executed epochs, so its last validation loss can differ from the
restored model's loss. `bestEpoch` is one-based.

Split datasets before fitting any normalization. Apply training-set scaling to
validation/test inputs. Measure generalization on a separate test set. XOR is
an educational convergence check, not evidence of real-world predictive quality.

## Save and load

```dart
final encoded = jsonEncode(network.toJson());
final restored = NeuralNetwork.fromJson(
  jsonDecode(encoded) as Map<String, dynamic>,
);
```

Import `dart:convert`. File/network IO belongs to the application. Models contain
architecture, seed and weights; optimizer moments and training progress are not
saved. A subsequent `fit` continues from current weights with fresh optimizer
state and a fresh seeded shuffle sequence. Parameter ordering is documented in
[architecture](doc/architecture.md).

## Runnable examples

```sh
dart pub get
dart run example/neural_engine_example.dart
dart run example/regression.dart
dart run example/classification.dart
```

The [Flutter lab](example/flutter_lab/README.md) has hidden-neuron and learning-rate
controls, an XOR decision surface, loss chart and predictions.

## Limits and roadmap

The initial release targets small dense models and educational/embedded app
workloads. Training is synchronous and allocates per-sample intermediate vectors.
Use an isolate for native Flutter workloads; on web use a worker for large jobs.
No GPU, CNN, recurrent layers, autodiff graph, pretrained model import, ONNX or
TensorFlow compatibility is provided. Seeded repeatability is tested within the
same SDK/platform; bit-identical results across all platforms are not promised.
Training mutates weights; do not share a network between concurrent operations.
Nonfinite updates throw; previously completed batches remain applied.

Next candidates: measured allocation/performance improvements, normalization
utilities, a separate neuroevolution example using `genetic_engine`, then new
layer types supported by numerical tests.

## Development

```sh
dart format --output=none --set-exit-if-changed lib test example
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

CI checks Dart 3.3 and stable, all CLI examples, JavaScript compilation, and the
Flutter lab separately. Release publication remains a manual step.

MIT © 2026 Kleber Andrade.

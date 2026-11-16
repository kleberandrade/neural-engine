# neural_engine

[![Dart CI](https://github.com/kleberandrade/neural-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/kleberandrade/neural-engine/actions/workflows/ci.yml)
[![MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Pure Dart neural networks for Flutter apps and Dart services: dense MLPs,
Kohonen self-organizing maps, trainable 2D CNNs and dense autoencoder examples.
Train locally and export versioned JSON models. No runtime dependencies, Flutter imports, native bindings
or network access in the core.

[Architecture and diagrams](doc/architecture.md) · [Sequence models](doc/recurrent.md) · [Evaluation](doc/evaluation.md) · [Model tutorials](doc/models.md) · [Guia didático](doc/models.pt-BR.md) · [Português](README.pt-BR.md) · [Concepts and architecture](doc/architecture.md) · [Flutter lab](example/flutter_lab/README.md) · [Contributing](CONTRIBUTING.md)

**Source version:** 0.2.0. See the [release preparation](doc/release_0.2.0.md). Publication remains a manual step.

## Models and runnable examples

| Family | Dart example | Flutter tab | Guide |
| --- | --- | --- | --- |
| MLP | [XOR](example/neural_engine_example.dart), [regression](example/regression.dart), [classes](example/classification.dart) | MLP: loss and decision surface | [MLP](doc/models.md#mlp-learn-a-relationship-between-vectors) |
| SOM | [RGB organization](example/som_colors.dart) | SOM: before/after color map | [SOM](doc/models.md#som-organize-colors-without-class-labels) |
| CNN | [Noisy bars](example/cnn_bars.dart) | CNN: image, probabilities, feature channels | [CNN](doc/models.md#cnn-learn-spatial-patterns-with-shared-filters) |
| Dense autoencoder | [Denoising](example/autoencoder.dart) | Autoencoder: input, target, reconstruction and latent code | [Autoencoder](doc/models.md#dense-autoencoder-compress-and-reconstruct) |

All examples use locally generated synthetic data. The guides explain shape
conventions, learning steps, practical experiments and evaluation limits.
RNN, LSTM and reset-before GRU are implemented as many-to-one models. See
[sequence forecasting](doc/recurrent.md) and the Flutter Sequences tab.

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

- Explicit model/trainer contracts and documented source/class architecture.
- RNN, LSTM and GRU cells with full BPTT, isolated state and JSON models.
- Training-only normalization, classification/regression metrics and reproducible [workload measurements](doc/benchmarks/README.md).

- Rectangular Kohonen SOM with Gaussian neighborhoods, decay schedules and JSON.
- End-to-end CNN: Conv2D, valid/same padding, stride, MaxPool2D, implicit flatten and Dense head.
- Dense autoencoder example, immutable layer outputs and input gradients.

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
| Binary / multilabel classification | sigmoid | `BinaryCrossEntropy` | Each value in `[0, 1]` |
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
dart run example/som_colors.dart
dart run example/cnn_bars.dart
dart run example/autoencoder.dart
dart run example/recurrent_sequences.dart
dart run example/evaluation.dart
```

The [Flutter lab](example/flutter_lab/README.md) has separate MLP, SOM, CNN and
autoencoder tabs, plus a Sequences comparison tab. Train each model and inspect its own curves and visualizations.

## Limits and roadmap

This implementation targets small models and educational/embedded app workloads. Training is synchronous and allocates per-sample intermediate vectors.
Use an isolate for native Flutter workloads; on web use a worker for large jobs.
No GPU, autodiff graph, pretrained model import, ONNX or
TensorFlow compatibility is provided. CNN supports standard square kernels and
valid max pooling; dilation, batch normalization and dropout are not implemented.
CNN, Dense and recurrent models share validation, early stopping and optional
global-norm clipping through `MiniBatchTrainer`.
SOM uses competitive learning and reports quantization error, not supervised loss. Seeded repeatability is tested within the
same SDK/platform; bit-identical results across all platforms are not promised.
Training mutates weights; do not share a network between concurrent operations.
Nonfinite updates throw; previously completed batches remain applied.

Future candidates include selected classical models and expanded recurrent configurations. Each
addition must include numerical checks, Dart/Flutter examples and a tutorial.
Allocation/performance improvements and normalization utilities remain useful
parallel priorities. See the [implemented/planned matrix](doc/models.md#implemented-and-planned).

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

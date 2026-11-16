# neural_engine

[![Dart CI](https://github.com/kleberandrade/neural-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/kleberandrade/neural-engine/actions/workflows/ci.yml)
[![MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/kleberandrade/neural-engine/blob/main/LICENSE)

Pure Dart neural networks for Flutter apps and Dart services: dense MLPs,
Kohonen self-organizing maps, trainable 2D CNNs and dense autoencoder examples.
Train locally and export versioned JSON models. No runtime dependencies, Flutter imports, native bindings
or network access in the core.

[Extension contracts](https://github.com/kleberandrade/neural-engine/blob/main/doc/extending.md) · [Persistence/checkpoints](https://github.com/kleberandrade/neural-engine/blob/main/doc/persistence.md) · [Architecture and diagrams](https://github.com/kleberandrade/neural-engine/blob/main/doc/architecture.md) · [Sequence models](https://github.com/kleberandrade/neural-engine/blob/main/doc/recurrent.md) · [Evaluation](https://github.com/kleberandrade/neural-engine/blob/main/doc/evaluation.md) · [Model tutorials](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.md) · [Guia didático](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.pt-BR.md) · [Português](https://github.com/kleberandrade/neural-engine/blob/main/README.pt-BR.md) · [Flutter lab](https://github.com/kleberandrade/neural-engine/blob/main/example/flutter_lab/README.md) · [Contributing](https://github.com/kleberandrade/neural-engine/blob/main/CONTRIBUTING.md)

**Package:** [neural_engine](https://pub.dev/packages/neural_engine), by verified publisher [kleberandrade.dev](https://pub.dev/publishers/kleberandrade.dev). See the [changelog](https://github.com/kleberandrade/neural-engine/blob/main/CHANGELOG.md).

## Models and runnable examples

| Family | Dart example | Flutter tab | Guide |
| --- | --- | --- | --- |
| MLP | [XOR](https://github.com/kleberandrade/neural-engine/blob/main/example/neural_engine_example.dart), [regression](https://github.com/kleberandrade/neural-engine/blob/main/example/regression.dart), [classes](https://github.com/kleberandrade/neural-engine/blob/main/example/classification.dart) | MLP: loss and decision surface | [MLP](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.md#mlp-learn-a-relationship-between-vectors) |
| SOM | [RGB organization](https://github.com/kleberandrade/neural-engine/blob/main/example/som_colors.dart) | SOM: before/after color map | [SOM](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.md#som-organize-colors-without-class-labels) |
| CNN | [Noisy bars](https://github.com/kleberandrade/neural-engine/blob/main/example/cnn_bars.dart) | CNN: image, probabilities, feature channels | [CNN](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.md#cnn-learn-spatial-patterns-with-shared-filters) |
| Dense autoencoder | [Denoising](https://github.com/kleberandrade/neural-engine/blob/main/example/autoencoder.dart) | Autoencoder: input, target, reconstruction and latent code | [Autoencoder](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.md#dense-autoencoder-compress-and-reconstruct) |

The model walkthroughs above use locally generated synthetic data; the Real data
tab adds the pinned datasets linked below. The guides explain shape
conventions, learning steps, practical experiments and evaluation limits.
RNN, LSTM and reset-before GRU are implemented as many-to-one models. See
[sequence forecasting](https://github.com/kleberandrade/neural-engine/blob/main/doc/recurrent.md) and the Flutter Sequences tab.

## Asynchronous training (0.4.0)

Version 0.4.0 adds incremental evaluation, a separate evaluation-progress stream
and explicit scheduling controls. Version 0.3.0 introduced native isolates, cooperative web batches, epoch
progress and safe cancellation/resume for MLP, CNN and recurrent models.
See the [async guide](https://github.com/kleberandrade/neural-engine/blob/main/doc/async_training.md)
and the Flutter **Async training** tab. Use version 0.3.0 or newer for these APIs.
See [real data examples](https://github.com/kleberandrade/neural-engine/blob/main/doc/real_world.md),
[responsiveness measurements](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/responsiveness.md) and the
[0.4.0 delivery status](https://github.com/kleberandrade/neural-engine/blob/main/doc/roadmap_0.4.0.md).

## Install

```yaml
dependencies:
  neural_engine: ^0.4.0
```

Dart >=3.3.0. Works in Flutter
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

- Fitted scaler JSON and fixed-epoch training checkpoints with Adam/SGD state.
- Independent external consumer validating custom models, losses and optimizers.

- Explicit model/trainer contracts and documented source/class architecture.
- RNN, LSTM and GRU cells with full BPTT, isolated state and JSON models.
- Training-only normalization, classification/regression metrics and reproducible [workload measurements](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/README.md).

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

Import `dart:convert`. File/network IO belongs to the application. Inference models contain architecture, seed and weights. For optimizer moments
and progress use the separate [TrainingSession checkpoint](https://github.com/kleberandrade/neural-engine/blob/main/doc/persistence.md). A subsequent `fit` continues from current weights with fresh optimizer
state and a fresh seeded shuffle sequence. Parameter ordering is documented in
[architecture](https://github.com/kleberandrade/neural-engine/blob/main/doc/architecture.md).

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
dart run example/custom_extensions.dart
dart run example/checkpoint.dart
dart run example/async_training.dart
dart run example/real_world.dart
```

The [Flutter lab](https://github.com/kleberandrade/neural-engine/blob/main/example/flutter_lab/README.md) has separate MLP, SOM, CNN and
autoencoder tabs, plus Sequences, Checkpoints, Async training and Real data.
Train each model and inspect its own curves and visualizations.

## Limits and roadmap

This implementation targets small models and educational/embedded app workloads. The default `fit` is synchronous; `AsyncTrainingTask` adds native isolate execution
and cooperative web batches. Intermediate vectors are still allocated per sample.
One large browser batch, one evaluation block and custom atomic evaluation remain synchronous units; see the
async guide for scheduling and cancellation limits.
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
parallel priorities. See the [implemented/planned matrix](https://github.com/kleberandrade/neural-engine/blob/main/doc/models.md#implemented-and-planned).

## Development

```sh
dart format --output=none --set-exit-if-changed lib test example
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

CI checks Dart 3.3 and stable, all CLI examples, JavaScript compilation, and the
Flutter lab separately. Stable releases use GitHub Actions with OIDC after the tag/version guard and
all release checks pass.

MIT © 2026 Kleber Andrade.

Try the Flutter **Checkpoints** tab to save/load JSON and compare resumed training
with uninterrupted execution. See [benchmarks](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/README.md),
[hosted validation](https://github.com/kleberandrade/neural-engine/blob/main/validation/hosted/README.md) and
[release procedure](https://github.com/kleberandrade/neural-engine/blob/main/doc/releasing.md).


0.4.0: [incremental evaluation and scheduling](https://github.com/kleberandrade/neural-engine/blob/main/doc/async_training.md), [measured results and limits](https://github.com/kleberandrade/neural-engine/blob/main/doc/benchmarks/scheduling_0.4.0.md).

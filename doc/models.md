# A practical guide to neural models

Use the runnable programs alongside this guide, then explore the Flutter lab.
All examples generate their own synthetic data locally; no downloads or services
are required. [Português](models.pt-BR.md) · [Architecture](architecture.md)

## Choose a model

| Model | Training inputs | Learns | Example |
| --- | --- | --- | --- |
| MLP | Vectors and desired outputs | Mapping from attributes to targets | XOR, regression, classification |
| Kohonen SOM | Vectors without labels | Prototypes arranged on a grid | RGB color organization |
| CNN | Images and desired outputs | Shared spatial filters and a decision | Vertical/horizontal bars |
| Dense autoencoder | Inputs and reconstruction targets | Encoding and reconstruction | Denoising patterns |

SOM uses competitive/neighborhood learning rather than backpropagation. CNN and
MLP use derivatives and optimizers. The autoencoder is an architecture built
from existing Dense layers, not a separate learning algorithm or model class.

Import `package:neural_engine/neural_engine.dart` for the snippets below. Snippets
with named datasets assume the data prepared by the complete linked program.
Shared generators live in `example/flutter_lab/lib/datasets.dart`, a pure Dart
file also imported by the CLI examples.

## MLP: learn a relationship between vectors

XOR is 1 when exactly one of two inputs is 1. A single linear boundary cannot
separate the four cases; a nonlinear hidden layer can represent this mapping.

```dart
final network = NeuralNetwork(inputSize: 2, seed: 42, layers: [
  Dense(8, activation: Activation.tanh),
  Dense(1, activation: Activation.sigmoid),
]);
final history = network.fit(
  inputs: [[0, 0], [0, 1], [1, 0], [1, 1]],
  targets: [[0], [1], [1], [0]],
  loss: const BinaryCrossEntropy(),
  optimizer: Adam(learningRate: 0.03),
  epochs: 1200, batchSize: 4,
);
print(network.predict([0, 1]));
```

`inputSize` counts features, not samples. Each inner list is one sample. `Dense(8)`
produces eight outputs; `Dense(1)` produces one. Choose sigmoid/BCE for binary or
multilabel outputs, softmax/CCE for exclusive classes, and linear/MSE for numeric
regression. An epoch visits the complete training set; a mini-batch produces one
update. Recorded loss is measured after a complete epoch.

```sh
dart run example/neural_engine_example.dart
dart run example/regression.dart
dart run example/classification.dart
```

**Experiment:** compare a linear network with the nonlinear hidden layer. Change
hidden neurons and learning rate in Flutter; inspect the decision surface and
loss rather than a single prediction.

## SOM: organize colors without class labels

Each color is a normalized `[r, g, b]` vector. Each neuron in a rectangular grid
stores an RGB prototype. For every sample, find the best matching unit (BMU),
move its prototype and neighboring prototypes toward the sample, then gradually
reduce the learning rate and neighborhood radius.

The update is `w ← (1 − αh)w + αhx`. The influence `h` is a Gaussian based on grid
distance from the BMU; closer cells move more. The grid does not wrap at edges.

```dart
final map = SelfOrganizingMap(rows: 6, columns: 6, inputSize: 3, seed: 42);
final history = map.fit(colors, epochs: 80, radius: 3, finalRadius: 0.4);
final match = map.winner([1, 0, 0]);
print('Red: row=${match.row}, column=${match.column}');
print(history.quantizationErrors.last);
```

```sh
dart run example/som_colors.dart
```

Quantization error is the average Euclidean distance to the BMU, not the average
squared distance. A smaller value indicates closer prototypes but does not
alone establish good topology. Error need not decrease every epoch. Coordinates
are not class labels: `(0, 0)` does not inherently mean red. A mirrored or rotated
map can also be a valid organization.

**Observe in Flutter:** compare the grid before and after; hover cells to inspect
RGB values. **Experiment in Dart:** compare 3×3 and 8×8 grids, then small and large
initial radii. Scale heterogeneous features so one large-unit feature does not
dominate Euclidean distance. Initial weights are uniform in the unit interval;
input scaling should be compatible.

## CNN: learn spatial patterns with shared filters

A CNN scans an image with a shared filter, learning patterns at different
positions. The example recognizes vertical and horizontal bars on 6×6 grayscale
images. Kernels and the dense head train jointly, end to end.

| Step | Output shape | Meaning |
| --- | --- | --- |
| Input | 6×6×1 | Grayscale pixels |
| Conv2D, four 3×3 filters, same padding, ReLU | 6×6×4 | Four feature channels |
| MaxPool2D, 2×2, stride 2 | 3×3×4 | Spatial downsampling per channel |
| Implicit flatten | 36 | HWC tensor converted into a vector |
| Dense + softmax | 2 | Vertical/horizontal probabilities |

```dart
final model = ConvolutionalNetwork(
  inputHeight: 6, inputWidth: 6, inputChannels: 1, seed: 42,
  layers: [
    Conv2D(filters: 4, kernelSize: 3, padding: ConvolutionPadding.same),
    MaxPool2D(),
  ],
  denseLayers: [Dense(2, activation: Activation.softmax)],
);
final history = model.fit(
  inputs: trainingImages, targets: trainingLabels,
  loss: const CategoricalCrossEntropy(),
  optimizer: Adam(learningRate: 0.02), epochs: 100, batchSize: 8,
);
```

```sh
dart run example/cnn_bars.dart
```

### Represent an image correctly

`ImageTensor` is immutable and stores positive height/width/channel dimensions.
Values use **HWC** order: row, column, then channel. For RGB, a pixel's three
channels are adjacent. Index: `(row * width + column) * channels + channel`.

```dart
final image = ImageTensor(
  height: 2, width: 2, channels: 1,
  values: [1, 0, 0, 1], // diagonal pixels
);
print(image.at(1, 1, 0)); // 1.0
```

`same` zero-pads and produces `ceil(input/stride)` outputs per spatial axis; it
preserves spatial size only at stride 1. Odd padding puts the extra cell at
bottom/right. `valid` adds no padding. Max pooling is valid and independent per
channel; ties route the gradient to the first matching position. Conv2D uses
cross-correlation, the usual CNN convention: kernels are not flipped.

`featureMaps(image)` returns the spatial tensor after every stage. Select a test
image and convolution channel in Flutter to inspect responses. Visualization
uses per-channel min/max contrast, so brightness is not comparable across
channels. Learned channels are not guaranteed to correspond to interpretable
edge detectors.

Targets are `[1, 0]` for vertical and `[0, 1]` for horizontal. Training and test
use different random noise but the same bar positions. Correct predictions do
not establish performance on photos, rotated shapes or unseen locations.

**Experiment:** remove pooling, change the filter count or noise strength.
Compare training loss with accuracy on separate data. Pooling discards fine
position detail; extra filters add parameters and CPU cost.

The initial CNN trainer supports mini-batches and training history. CNN now supports validation and early stopping through the shared trainer;
see [evaluation](evaluation.md) and keep a separate final test set. Backpropagation passes through
the dense head, implicit flatten, pooling routes and convolution kernels.

## Dense autoencoder: compress and reconstruct

An autoencoder can use the input itself as its target. A denoising autoencoder
instead reconstructs the corresponding clean target from a noisy input. This
example maps eight values through a two-coordinate bottleneck back to eight
values, using independently learned encoder/decoder weights.

```dart
final model = NeuralNetwork(inputSize: 8, seed: 42, layers: [
  Dense(6, activation: Activation.tanh),
  Dense(2, activation: Activation.tanh), // latent bottleneck
  Dense(6, activation: Activation.tanh),
  Dense(8, activation: Activation.sigmoid),
]);
final history = model.fit(
  inputs: noisyPatterns, targets: cleanPatterns,
  loss: const BinaryCrossEntropy(),
  optimizer: Adam(learningRate: 0.02), epochs: 400, batchSize: 8,
);
final code = model.layerOutputs(noisyPatterns.first)[1];
final reconstruction = model.predict(noisyPatterns.first);
```

```sh
dart run example/autoencoder.dart
```

Sigmoid/BCE matches the unit-range target representation; MSE reports held-out
reconstruction error. Flutter displays noisy input, clean target, reconstruction
and latent coordinates. `layerOutputs` returns immutable snapshots, excluding
the input layer, so index 1 is the second Dense layer.

The data contains four familiar patterns with new noise realizations at test
time. Low reconstruction error here does not establish anomaly detection,
fraud detection or useful compression on real-world data.

**Experiment:** increase noise, then reduce the bottleneck to one neuron.
Evaluate separate test samples rather than only training reconstructions.

## Persistence and evaluation

MLP, SOM and CNN each support versioned `toJson`/`fromJson` formats; use the
constructor matching the family. Dense autoencoders use the MLP format.
Imports validate architecture, finite values and dimensions. Optimizer moments
and training progress are not saved; file/network IO belongs to the application.

```dart
// Add import 'dart:convert'; model here is a trained CNN.
final encoded = jsonEncode(model.toJson());
final restored = ConvolutionalNetwork.fromJson(
  jsonDecode(encoded) as Map<String, dynamic>,
);
```

Use `SelfOrganizingMap.fromJson` for SOM and `NeuralNetwork.fromJson` for MLP or
its autoencoder architecture. Every new `fit` retains weights but restarts
optimizer state and the seeded shuffle sequence. SOM also restarts its decay
schedule on each call.

Split datasets before fitting normalization; reuse training statistics at test
time. Do not repeatedly tune hyperparameters against the final test set. Seeds
support repeatability within the same SDK/platform, not a promise of identical
floating-point results on every platform.

## Implemented and planned

| Family | Status |
| --- | --- |
| Dense MLP and dense autoencoder | Implemented; Dart and Flutter examples |
| Rectangular Kohonen SOM | Implemented; Dart and Flutter examples |
| CNN 2D with max pooling | Implemented; Dart and Flutter examples |
| RNN, LSTM, GRU | Implemented many-to-one; [sequence guide](recurrent.md), Dart/Flutter examples |
| Hopfield, RBF and other classical models | Candidates for later stages |
| Transformers, GPU, ONNX import | Outside this stage |

Each new family should have a clear API, applicable numerical tests, runnable
Dart example, Flutter demonstration and a tutorial with limitations. The core
remains pure Dart. No integration with another engine is part of this stage.

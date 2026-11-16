# Validated public-API extensibility

[Português](extending.pt-BR.md) · [Persistence](persistence.md)

`example/extensions/` is an independent Dart consumer package with its own
pubspec. It imports only `package:neural_engine/neural_engine.dart`, never internal
source. CI resolves, analyzes and executes it on minimum and stable SDKs.

```sh
dart run example/custom_extensions.dart
cd example/extensions
dart pub get
dart analyze --fatal-infos
dart run main.dart
```

- HuberLoss implements Loss and works with the built-in dense model. Every
  parameter derivative is checked by finite differences on a small fixture.
- MomentumOptimizer implements optional checkpoint contracts with application-owned
  versioned state codecs. Each fit owns its velocity state.
- LinearModel implements DifferentiableModel/JsonModel, without subclassing
  NeuralNetwork. MiniBatchTrainer fits it directly.

The consumer checks convergence and exact checkpoint continuation through custom
model/optimizer decoders, with no SDK registry changes. Read the separate source
files under `example/extensions` for complete implementations.

Contracts require independent prediction/parameter snapshots, finite evaluation,
a sample gradient matching parameter order/count, and optimizer updates to the
candidate vector only. Boundary tests reject mismatched gradients, nonfinite
custom evaluation and an optimizer changing parameter-vector length before
committing invalid weights. Custom codec validation remains its author's job.

SpatialLayer execution/serialization still requires explicit CNN support; new
RecurrentCell implementations can be composed by applications, while the built-in
RecurrentKind selector and JSON support known RNN/LSTM/GRU variants only. These
interfaces do not pretend to be a universal layer registry or autodiff engine.

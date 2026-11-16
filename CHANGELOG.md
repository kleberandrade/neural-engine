# Changelog

## Unreleased

## 0.2.0

- Reorganize source into contracts, layers, family executors, training, metrics and preprocessing modules; keep the public package import stable.
- Add an architecture source map, class/dependency diagrams, numerical contracts and JSON layout documentation.
- Share mini-batch training across Dense, CNN and recurrent models, including CNN validation/early stopping and optional global-norm clipping.
- Add many-to-one RNN, LSTM and reset-before GRU with full BPTT, state traces and versioned JSON.
- Add StandardScaler, MinMaxScaler, classification/regression metrics, SOM U-matrix/hit maps and a CNN drawing widget.
- Reorganize Flutter into pages, runners, data, widgets and painters; add sequence-model comparison.
- Record reproducible local workload measurements and prepare manual release verification.

- Add Kohonen SOM with Gaussian neighborhood learning, quantization history and versioned JSON.
- Add end-to-end Conv2D/MaxPool2D networks with HWC tensors, padding, stride and dense heads.
- Add dense input gradients and immutable intermediate outputs for composition and autoencoder inspection.
- Add SOM, CNN and denoising autoencoder examples in Dart and dedicated Flutter lab tabs.
- Add bilingual model tutorials, numerical spatial tests and a model-focused roadmap.

- Keep the Flutter lab compatible with both legacy Material imports and the latest stable SDK deprecation checks.

## 0.1.0

- Initial pure Dart MLP with Dense layers and six activation functions.
- MSE, stable binary/categorical cross entropy, mini-batch SGD and Adam.
- Seeded initialization/shuffling, validation history and early stopping.
- Versioned JSON inference models, parameter snapshots and analytic gradients.
- Public-API numerical tests, CLI examples and interactive Flutter XOR lab.
- English/Portuguese documentation and Dart/Flutter CI.

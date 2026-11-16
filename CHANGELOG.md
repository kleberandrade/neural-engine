# Changelog

## 0.3.0

- Add offline Iris classification and chronological AirPassengers forecasting examples shared by Dart/Flutter, with training-only scalers, reserved tests, baselines and dataset provenance.
- Record reproducible native/Chrome responsiveness, cancellation, sampled-memory and executor-step measurements; document a measured 0.4.0 plan.
- Add native isolate workers and cooperative web mini-batches through AsyncTrainingTask.
- Share the synchronous batch executor with TrainingSession.fitAsync; support custom model/loss/optimizer contracts cooperatively.
- Stream epoch progress, training/validation loss and elapsed time; cancel at complete epoch boundaries and resume existing JSON checkpoints.
- Add an Async training Flutter tab for MLP/CNN/RNN/LSTM/GRU/autoencoder with live charts, cancellation, load/resume and asynchronous reference comparison.
- Add bilingual scheduling/lifecycle guides, platform limits, architecture diagrams and native/JavaScript/Flutter lifecycle tests.

## 0.2.1

- Fix pub.dev installation instructions and make README documentation links absolute.
- Verify the exact hosted 0.2.0 artifact with an isolated minimum/stable Dart consumer, all model JSON codecs, scalers and disk-backed checkpoint continuation.
- Add a Flutter Checkpoints tab with editable/copyable JSON, fresh model restoration, Adam continuation and comparison against uninterrupted training for MLP/CNN/RNN/LSTM/GRU.
- Measure compact model JSON sizes and SOM inference alongside reproducible training/inference workloads.
- Generalize stable release tags with an exact tag/pubspec guard and mandatory CI before OIDC publication.

## 0.2.0

- Validate extensibility with an independent public-API consumer: Huber loss, momentum optimizer and a custom linear model.
- Persist fitted StandardScaler/MinMaxScaler statistics with validated versioned JSON.
- Add fixed-epoch TrainingSession checkpoints, Adam moments/step, SGD state and deterministic epoch continuation.
- Support application-owned model/optimizer checkpoint decoders and reject malformed extension boundary results.
- Add cross-family exact replay tests and bilingual extension/persistence guides.

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

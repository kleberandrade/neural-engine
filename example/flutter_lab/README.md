# Neural Engine Model Lab

Six independent tabs train models using locally generated data:

| Tab | Training | Visualizations |
| --- | --- | --- |
| MLP | XOR with configurable hidden neurons and learning rate | Loss, decision surface, predictions |
| SOM | 6×6 Kohonen map of RGB samples | Before/after prototypes, quantization curve, BMU coordinates |
| CNN | 6×6 noisy vertical/horizontal bars | Input image, class probabilities, selectable convolution channel |
| Autoencoder | Denoising, Dense 8→6→2→6→8 | Noisy input, clean target, reconstruction, latent coordinates |
| Sequences | RNN, LSTM and GRU on the same six-step sine input | Model comparison, loss, next prediction, hidden/memory states |
| Checkpoints | Save/load and 40 + 60 epoch Adam continuation for five model families | Editable JSON, bytes, loss, predictions and exact reference comparison |

```sh
flutter pub get
flutter test
flutter run -d chrome
```

Web runner files are bundled. Generate other platform runners with
`flutter create --platforms=android,ios,macos .` as needed. UI is in English.
Read the [English tutorial](../../doc/models.md) or [guia em português](../../doc/models.pt-BR.md)
for the meaning of each model, data shapes, experiments and limitations.

Models run on demand; selecting a tab does not train automatically. Training uses
`compute` (a worker isolate on native platforms, the main event loop on Flutter
Web). Web training can briefly block; use dedicated workers for larger workloads.
Core training is synchronous. Plots refer to the last completed run.

CNN image and channel sliders inspect held-out noise samples. Feature maps use
per-channel contrast normalization, not an absolute scale across filters.
SOM cells show RGB prototypes with tooltips. Autoencoder examples reconstruct four
familiar patterns with new noise; latent coordinates are learned, not class labels.
Shared generators in `lib/datasets.dart` are pure Dart and reused by CLI examples.

Widget tests train all model tabs, recreate the checkpoint page and check narrow-screen rendering. Synthetic
data and tiny networks are educational examples, not performance benchmarks or
claims of real-world generalization.


## Source organization

`main.dart` only starts the application. `app.dart` owns the theme; `pages/`
owns navigation and state; `runners/` owns compute entry points; `data/` owns
synthetic fixtures; `widgets/` and `painters/` own rendering. `datasets.dart` and
`sequence_dataset.dart` are pure Dart fixture exports for CLI programs.

CNN includes a drawable 6×6 canvas and probability output. SOM adds a U-matrix
(mean adjacent prototype distances) and BMU hit counts; tooltip values are real
values even when color contrast is normalized. Read the architecture source map
and recurrent guide before adding another model/demo.

## Checkpoint walkthrough

1. Open **Checkpoints** and select MLP, CNN, RNN, LSTM or GRU.
2. Press **Train 40 epochs**. Inspect mean training loss, predictions and JSON size.
3. Press **Copy JSON to save**, then save the clipboard text in a local `.json` file.
4. Close/reopen the app, select the same model, paste the file contents in
   **Checkpoint JSON**, then press **Load JSON**. Predictions must stay identical.
5. Press **Resume +60 epochs**. The page compares restored predictions, weights
   and Adam state against a fresh uninterrupted 100-epoch reference run. For an
   untouched checkpoint on the same SDK/platform the state comparison is `true`
   and the maximum prediction difference is zero.

The JSON editor accepts this demo's versioned envelope at epochs 40 or 100;
invalid JSON, wrong families and unsupported settings report an error without
replacing the last successful result. You can load epoch 100 for inference, but
resuming this fixed walkthrough requires epoch 40. This page uses the fixed
synthetic datasets and training recipe in `runners/checkpoint_runner.dart`.

Clipboard export is explicit and does not automatically create a filesystem
file. No storage plugin is required, including on web. The pure Dart
[checkpoint example](../checkpoint.dart) explains the core API; the
[hosted consumer](../../validation/hosted/README.md) demonstrates actual file IO.
SOM's independent neighborhood/decay schedule is outside `TrainingSession`.

## Async training (0.3.0 development)

Use **Async training** for MLP/CNN/RNN/LSTM/GRU/autoencoder with native isolates or
cooperative web batches, live epoch/loss/validation/time, interaction counter,
cancel, copy/load JSON, resume and asynchronous uninterrupted-run comparison.
The old model visualization tabs remain standalone recipes. SOM has a separate
unsupervised schedule. Web compute in old tabs is not a parallel worker.
See [English](../../doc/async_training.md) / [Português](../../doc/async_training.pt-BR.md)
for epoch-boundary cancellation and browser scheduling limits.

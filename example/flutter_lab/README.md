# Neural Engine Model Lab

The responsive navbar opens **Laboratory**, **Learn**, **Examples**, documentation and GitHub.
The laboratory preserves eight independent model workspaces:

| Tab | Training | Visualizations |
| --- | --- | --- |
| MLP | XOR with configurable hidden neurons and learning rate | Loss, decision surface, predictions |
| SOM | 6×6 Kohonen map of RGB samples | Before/after prototypes, quantization curve, BMU coordinates |
| CNN | 6×6 noisy vertical/horizontal bars | Input image, class probabilities, selectable convolution channel |
| Autoencoder | Denoising, Dense 8→6→2→6→8 | Noisy input, clean target, reconstruction, latent coordinates |
| Sequences | RNN, LSTM and GRU on the same six-step sine input | Model comparison, loss, next prediction, hidden/memory states |
| Checkpoints | Save/load and 40 + 60 epoch Adam continuation for five model families | Editable JSON, bytes, loss, predictions and exact reference comparison |
| Async training | Bounded MLP/CNN/RNN/LSTM/GRU/autoencoder recipes | Live train/validation loss, pause/cancel/resume, JSON and exact replay |
| Real data | Offline Iris MLP and AirPassengers GRU | Live curves, reserved-test metrics, confusion matrix, predictions and baselines |

Validated toolchain: **Flutter 3.50.0 / Dart 3.14.0**. The Dart core retains its
Dart >=3.3.0 contract; this lab targets Flutter >=3.50.0. CI pins the Flutter
version and the app lockfile records compatible resolved dependencies.

[Open the web laboratory](https://kleberandrade.github.io/neural-engine/) ·
[Scenario guide](../../doc/lab_scenarios.md) · [Validation and real captures](../../doc/lab_validation.md)

```sh
flutter pub get
flutter test --exclude-tags benchmark
flutter run -d chrome
```

Web runner files are bundled. Generate other platform runners with
`flutter create --platforms=android,ios,macos .` as needed. The complete UI and integrated lessons support English and Brazilian Portuguese.
Read the [English tutorial](../../doc/models.md) or [guia em português](../../doc/models.pt-BR.md)
for the meaning of each model, data shapes, experiments and limitations.

Models run on demand; selecting a tab does not train automatically. Training uses
`compute` (a worker isolate on native platforms, the main event loop on Flutter
Web). Web training can briefly block; use dedicated workers for larger workloads.
The standalone model runners are synchronous; the core also exposes asynchronous training. Plots refer to the last completed run.

CNN image and channel sliders inspect held-out noise samples. Feature maps use
per-channel contrast normalization, not an absolute scale across filters.
SOM cells show RGB prototypes with tooltips. Autoencoder examples reconstruct four
familiar patterns with new noise; latent coordinates are learned, not class labels.
Shared generators in `lib/datasets.dart` are pure Dart and reused by CLI examples.

Widget tests train all model tabs, recreate the checkpoint page and check narrow-screen rendering. Synthetic
data and tiny networks are educational examples, not performance benchmarks or
claims of real-world generalization.


## Navigation, language and integrated learning

The original N-shaped neural graph is drawn in Flutter and supplied as a local
SVG/favicon plus PNG icon variants. Circular Brazil and United Kingdom selectors
are drawn locally, with language tooltips, selected borders, keyboard focus and
48 px targets. These project-authored geometric assets are covered by MIT.

Switching sections or EN/PT-BR preserves the model, controls and training session.
`shared_preferences` persists the language where storage is available; if access
is blocked, the app retains the selection for the current session. It does not
automatically persist checkpoints. `url_launcher` opens real source documentation
in a new tab; the native app also uses the platform browser when available.

**Learn** covers the implemented MLP, SOM, CNN, autoencoder and RNN/LSTM/GRU
algorithms, evaluation and exact continuation. Each chapter includes an interpreted
formula, a real public-API snippet, an implemented preset and its English/PT-BR
source guide. References precede exactly five exercises with objectives and
completion criteria. **Examples** loads nine deterministic recipes without
starting training. Loading an MLP preset changes its hidden size; real-data presets
select Iris or AirPassengers. Active runs are protected from recipe replacement.

The UI targets Material UI 1.11.1, shared_preferences 2.5.6 and url_launcher 6.3.3
on the validated Flutter SDK. These remain confined to the example application;
the Dart core has no Flutter or runtime dependencies.

## Source organization

`main.dart` loads the optional saved language preference and starts the application. `app.dart` owns the theme and locale; `l10n/` owns translations; `content/` owns source-backed lessons, links and presets; `pages/`
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
file. Checkpoints are never stored automatically. The optional preference store persists only the selected language, not models, datasets or JSON. The pure Dart
[checkpoint example](../checkpoint.dart) explains the core API; the
[hosted consumer](../../validation/hosted/README.md) demonstrates actual file IO.
SOM's independent neighborhood/decay schedule is outside `TrainingSession`.

## Async training (0.3.0)

Use **Async training** for MLP/CNN/RNN/LSTM/GRU/autoencoder with native isolates or
cooperative web batches, live epoch/loss/validation/time, interaction counter,
cancel, copy/load JSON, resume and asynchronous uninterrupted-run comparison.
The old model visualization tabs remain standalone recipes. Pause finishes the current epoch and saves a resumable checkpoint; Reset clears the experiment when idle.
Architecture, data counts and hyperparameters are visible with training and validation curves.
Imported checkpoints must match the bounded recipe. SOM has a separate
unsupervised schedule. Web compute in old tabs is not a parallel worker.
See [English](../../doc/async_training.md) / [Português](../../doc/async_training.pt-BR.md)
for epoch-boundary cancellation and browser scheduling limits.

## Real data

The **Real data** tab runs the same offline Iris and AirPassengers recipes as
`dart run example/real_world.dart`. It reports reserved-test metrics and simple
baselines, including when the GRU loses. [Tutorial](../../doc/real_world.pt-BR.md).
The benchmark-tagged test records native/Chrome event-loop observations, not FPS.

## Static hosting

The CI workflow builds with `--release --no-web-resources-cdn --base-href /neural-engine/`.
GitHub Pages deployment depends on the Dart, Flutter and hosted-consumer test jobs.
Pull requests build but never deploy. The Web renderer and fonts are bundled for
the first-party static host; no paid service or backend is required.

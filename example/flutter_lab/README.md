# Neural Engine Model Lab

Five independent tabs train models using locally generated data:

| Tab | Training | Visualizations |
| --- | --- | --- |
| MLP | XOR with configurable hidden neurons and learning rate | Loss, decision surface, predictions |
| SOM | 6×6 Kohonen map of RGB samples | Before/after prototypes, quantization curve, BMU coordinates |
| CNN | 6×6 noisy vertical/horizontal bars | Input image, class probabilities, selectable convolution channel |
| Autoencoder | Denoising, Dense 8→6→2→6→8 | Noisy input, clean target, reconstruction, latent coordinates |
| Sequences | RNN, LSTM and GRU on the same six-step sine input | Model comparison, loss, next prediction, hidden/memory states |

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

Widget tests train all five tabs and check narrow-screen rendering. Synthetic
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

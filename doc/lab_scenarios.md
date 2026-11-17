# Neural Engine laboratory scenarios

The UI lives in `example/flutter_lab`; `lib/` remains a Flutter-free Dart library.
All datasets are offline and all training runs locally on the CPU. No accounts,
remote inference services or dataset uploads are required. Start with MLP, then
compare SOM, CNN, autoencoder and sequence models before studying checkpoints.

## Choose an experiment

**MLP / XOR.** Change hidden neurons (2–16) and Adam learning rate (0.005–0.1),
then train the 2 → tanh → sigmoid network for 800 epochs with seed 42. Inspect
binary cross entropy, all four predictions and the decision surface. These four
truth-table rows constitute the entire task; the reused validation rows in Async
training are a fit check, not evidence of generalization.

**SOM / colors.** Train a 6×6 map on RGB vectors for 80 epochs. Learning rate decays
0.5 → 0.05 and radius 3 → 0.4. Compare prototype organization, quantization error,
U-matrix and sample hits. There are no class targets or classification accuracy.
Coordinates identify prototypes, not meaningful named color classes.

**CNN / noisy bars.** Train on 16 synthetic 6×6 images. A 3×3 convolution with
four ReLU filters and same padding feeds max pooling and a two-class softmax
head. Adam 0.02, batch 8, 100 epochs. Inspect held-out accuracy on eight different
noise samples, class probabilities and feature channels. Draw a new pattern with
a pointer or toggle individual pixels using Tab and Enter. Clear removes the
previous prediction. New noise at familiar positions is not a test on new shape
families or photographs; arbitrary drawings may be out of distribution.

**Autoencoder / denoising.** Dense 8 → 6 → 2 → 6 → 8, Adam 0.02, batch 8,
400 epochs, binary cross entropy. Compare 20 training and 20 new-noise test
patterns using reconstruction MSE, noisy input, clean targets and latent values.
There are only four underlying clean patterns. Latent values are learned
coordinates; this does not validate anomaly detection on real data.

**Sequences / sine waves.** Compare many-to-one RNN, LSTM and GRU on 24 six-step
windows, six hidden units, Adam 0.015, batch 8 and gradient clip 1. Change epochs
and inspect loss, MAE/MSE, prediction curves and hidden/memory states. The 24 test
phases interleave the training phases; this is interpolation on one sine family.
Async training uses Adam 0.02 for its separate replay recipe, shown in its card.

**Checkpoints.** Train 40 epochs, copy JSON, recreate the page, load and resume
60 more. Compare model and Adam state with an uninterrupted 100-epoch reference.
This is a fixed walkthrough; it deliberately differs from other pages' recipes.
The async and checkpoint pages use separate envelope formats and reject each
other's exports. JSON remains in memory until explicitly copied and saved.

**Async training.** Select MLP, CNN, RNN, LSTM, GRU or autoencoder. The recipe card
shows architecture, sample counts, loss, optimizer, batch size and seeds. Choose
10–1000 total epochs before starting. Training and validation share the chart's
vertical scale: cyan line for training, amber line with dots for validation.
Numerical start/end values and screen-reader descriptions accompany the chart.
Resume charts describe only the current run, not pre-import history.

- **Pause training** finishes the current epoch and saves an exact checkpoint.
- **Resume checkpoint** continues toward the original epoch goal.
- **Cancel safely** uses the same safe boundary, retaining a resumable checkpoint.
- **Start fresh** replaces the saved model with a newly seeded run.
- **Reset experiment** clears results, errors, checkpoint and JSON when idle.
- **Compare uninterrupted** checks exact replay on the same runtime/platform.
- **UI interactions** demonstrates that cooperative work still accepts input.

Imported JSON must match the selected fixed recipe's architecture, optimizer and
seed; learned weights and optimizer state are validated when restoring. Changing
families clears the previous run. Copy JSON before reset, starting fresh or closing
the tab. A checkpoint is not a dataset: replay needs this version's exact recipe.

**Real data.** Iris uses deduplication, a stratified split and a scaler fitted on
training data only. Train MLP 4 → 8 tanh → 3 softmax for 120 epochs, Adam 0.01,
batch 16. Inspect live training/validation curves, final reserved-test accuracy,
macro F1, confusion matrix, sample predictions and training-majority baseline.
AirPassengers uses GRU hidden size 8 with 12 monthly lags, 100 epochs, Adam 0.01,
batch 12 and chronological order. Training ends in 1956, validation in 1958 and
test in 1960. Test MAE/RMSE use thousands of passengers. Compare previous-month
and previous-year baselines, even when they beat the GRU. These are one-step
forecasts using prior observations, not a recursive two-year forecast. Cancellation
does not evaluate the test set; retraining starts fresh.

## Browser limits and accessibility

Use Async training for interactive supervised work. Web runs cooperative batches
on the main event loop; it does not create a parallel worker. One large batch or
evaluation block can still block a frame. The optional 8 ms budget is checked
between work units and is not a frame-time guarantee. Smaller yield frequency and
evaluation chunks improve opportunities for input at a possible throughput cost.
Pause/cancel can take an epoch to finish. Native execution uses an isolate.

The standalone model pages are small synchronous recipes using Flutter `compute`;
on Web they may briefly block and have no mid-run cancellation. SOM has a separate
unsupervised schedule. Do not scale these recipes to large datasets in a browser.

Tabs scroll horizontally on phones. Content scrolls vertically and charts stack
on narrow screens. Numerical values accompany color encodings. CNN pixels have
row/column labels, toggle state and keyboard activation. Loss summaries and training
status expose semantics. Screen-reader output was inspected through the browser
accessibility tree; a full assistive-technology audit remains outside these checks.

## Sources and verification

- [Dataset origins and attribution](../example/data/README.md).
- [Model guide](models.md) and [guia em português](models.pt-BR.md).
- [Architecture](architecture.md), [async API](async_training.md), [evaluation](evaluation.md).
- [Actual validation evidence and screenshots](lab_validation.md).

## Five practical exercises

1. **XOR capacity.** Compare 2 and 16 hidden neurons at the same learning rate.
   Complete when you record both final losses and all four predicted classes.
2. **SOM topology.** Train once and compare before/after maps with the U-matrix.
   Complete when you identify two adjacent similar prototypes and report their RGB values.
3. **CNN distribution.** Classify a vertical bar and a diagonal drawing.
   Complete when you record both probability vectors and explain why only the bar matches training data.
4. **Exact continuation.** Pause an async CNN run, copy/load JSON, resume and compare.
   Complete when the target epoch is reached and exact checkpoint match is true on the same platform.
5. **Honest forecasting.** Train AirPassengers and compare test MAE with both baselines.
   Complete when you name the best method and state the test dates and one-step forecast limitation.

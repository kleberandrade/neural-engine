# Engineering log

## Initial 0.1.0 implementation

Action: create an independent pure Dart dense neural-network package with
training, inference and JSON interchange, plus CLI and Flutter examples.
Reason: extend the engine family with supervised gradient-based learning.

Local validation (Dart 3.11.5 / Flutter 3.41.9, macOS arm64):

- 19 public-API tests passed, including every-parameter finite differences,
  extreme-logit stability, seeded XOR convergence, SGD regression, multiclass
  classification, optimizer isolation, JSON roundtrip and early stopping.
- Core analyzer and Flutter lab analyzer passed with no issues.
- Three CLI examples passed their convergence assertions.
- Core XOR example compiled to JavaScript.
- Flutter widget test could not start its localhost socket under the execution
  sandbox. Flutter web build was blocked by a child compiler analytics write
  outside the writable workspace. These are not recorded as passing checks.
- Full publish dry-run needs network access unavailable to the shell here;
  GitHub CI performs this validation before a manual publish is considered.

CI is configured for Dart minimum/stable and Flutter stable. Its actual results
must be inspected independently; configuration alone is not a passing result.

CI follow-up: Dart 3.3.4 and stable jobs passed, including the publish dry-run.
Latest Flutter stable deprecated the legacy Material forwarding import. Keep
that import for compatibility with older Flutter versions and suppress only
its specific deprecation at the two import sites. The first Flutter CI run
stopped at analysis; a new run validates the change. Local direct compilation
of the complete Flutter lab to JavaScript also succeeded.

## SOM, CNN and teaching examples

Action: add independent Kohonen SOM and trainable Conv2D/MaxPool2D models; expose
dense input derivatives and immutable layer outputs; add a dense denoising
autoencoder example. Replace the neuroevolution roadmap with model families.
Reason: focus this repository on neural architectures with explanatory Dart and
Flutter examples, keeping other engines independent.

Validation: 28 public-API tests pass locally, including finite differences across
all CNN parameters (multiple input channels, stacked filters, overlapping pooling,
valid/same padding and stride), known spatial updates, dense input gradients,
SOM learning/neighborhood behavior and held-out-noise reconstruction. Core
analysis passes. CNN also compiles and runs under Node.js. RGB quantization
error and synthetic shape/reconstruction results are educational fixture checks,
not real-world benchmarks. Full Flutter UI and web-build checks run in CI.

## Structured architecture and 0.2.0 preparation

Action: replace monolithic family files with contracts, specifications, executors,
training, preprocessing and metrics modules; reorganize Flutter into pages,
runners, data, painters and widgets. Add source/dependency/class diagrams and
explicit extension boundaries. Preserve the public library and v1 model formats.

Then consolidate evaluation/CNN early stopping, add RNN/LSTM/reset-before GRU with
full BPTT and separate state/cache objects, add sequence comparison, drawable CNN
inputs and SOM U-matrix/hit maps. Record reproducible workload measurements and
prepare version 0.2.0 for manual publication.

Verification includes the original 28 public tests after refactoring plus
numerical recurrent gradients across every parameter, shared CNN stopping,
normalization, known metric values, clipping and SOM grid diagnostics. Sequence
CLI asserts held-out synthetic MSE and JSON roundtrip for all three cells.
The latest CI must be checked independently for Flutter and publication dry-run.

CI follow-up: both Dart jobs passed, including minimum SDK, JavaScript examples
and publish dry-run. Four of five Flutter tests passed; the drawing action was
built in the sliver cache but outside the viewport. The test now scrolls until
the actual button is hit-testable before sending the pointer event.

## Extensibility and persistence completion

An independent Dart consumer now supplies a Huber loss, momentum optimizer and
linear model through public contracts, including custom checkpoint codecs.
Fitted scaler JSON restores training statistics without refitting. TrainingSession
retains Adam/SGD state and uses absolute-epoch shuffles, with checkpoints only at
completed fit boundaries. Fixed-epoch sessions intentionally do not combine
best-weight early stopping with newer optimizer moments.

55 public tests pass locally, including exact full/split replay across Dense,
CNN and all three recurrent variants for Adam/SGD, malformed state rejection,
immutable snapshots and invalid custom model/optimizer boundaries. External
consumer analysis and execution also pass independently. Pub.dev currently has
0.1.0 under the user's uploader identity; 0.2.0 remains the release target.

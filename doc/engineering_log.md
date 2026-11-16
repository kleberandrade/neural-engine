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

## 0.4.0 local implementation and release gates

Added optional sample-loss evaluation, typed trainer phases, chunked preflight
and epoch evaluation, a separate evaluation progress stream, configurable pause
frequency and an optional between-unit work budget. Legacy custom evaluators and
steps adapters retain their contracts; v1 checkpoints and complete-epoch
cancellation remain. Flutter exposes the controls and progress.

Local verification: 125 core tests pass on Dart 3.11.5/macOS arm64. Core and
Flutter analyzers are clean. The strengthened native and compiled-JavaScript
portability consumer verifies all six demo recipes across yield policies,
including evaluation-event transport and complete optimizer/checkpoint equality.
The new validation-only forecasting CLI also completes in native Dart and
JavaScript. The Flutter release frame-probe source compiles to JavaScript;
this compilation alone is not a release-build trace or interaction test.

The fixed-batch native matrix and four-candidate validation forecast results are
archived under doc/benchmarks. Forecast selection remains behind seasonal
baselines, excludes the previously published test, and makes no generalization
claim. Allocation/profile and native/Chrome release-frame collectors are prepared,
but successful remote evidence remains a release gate. No buffer reuse or worker
pool has been added before profiling. Physical-device frame evidence is outstanding.

Commits are saved locally. Push/publication are blocked in this execution
environment: shell GitHub DNS is unavailable and GitHub Desktop has no accessible
window. No v0.4.0 tag or pub.dev upload has been made. Resume with a visible
repository window, push, inspect CI/performance results, correct any failures,
then publish through the existing OIDC workflow and verify the exact hosted
artifact. Keep the hosted consumer pinned to 0.3.0 until 0.4.0 exists publicly.


0.4.0 remote follow-up: commits were pushed successfully via GitHub Desktop.
[Source CI 43975841654](https://github.com/kleberandrade/neural-engine/actions/runs/43975841654)
passed minimum/stable Dart, Flutter interaction tests, native/Chrome fixed-batch
matrices, JavaScript examples and publication dry run.
[Performance evidence 43975841544](https://github.com/kleberandrade/neural-engine/actions/runs/43975841544)
passed both allocation and actual release-frame jobs. Baseline/current parameters
and losses match; counters/throughput show extra executor cost, not a speedup.
Release-app checkpoints match per platform and execution policy. Permanent
summaries and links to full metadata/traces are in doc/benchmarks. Physical-device
evidence and optimizer-buffer attribution remain deferred. These remote results
supersede the earlier push-blocked state above.


Publication follow-up: v0.4.0 was published successfully by workflow
43977287304 at release commit 22ef129. Pub.dev confirms version 0.4.0 under
kleberandrade.dev. The independent consumer was advanced after upload and now
exercises the new evaluation stream/options through the exact hosted dependency.

# Responsiveness measurements

Run `dart run benchmark/responsiveness.dart` and `dart run benchmark/batch_latency.dart`.
Flutter hosts run `test/responsiveness_test.dart` on the native test engine and
Chrome headless. CI uploads the two complete JSON reports as `flutter-responsiveness`.
The ordinary widget suite excludes the `benchmark` tag to avoid measuring twice.

## Protocol and interpretation

- Fixed seed 42, MLP/CNN/GRU recipes, Adam 0.02, clipping 1, batch sizes 1 and 8.
- Native automatic mode uses a worker isolate; cooperative mode runs in the caller.
  In Chrome, both automatic and cooperative use the browser event loop.
- Three repetitions per scenario, one-epoch warmup with fresh measurement weights,
  eight measured epochs. Wall time includes worker startup, encoding and transport.
- A 1 ms periodic timer samples caller event-loop delay beyond its requested period.
  This is a responsiveness proxy, **not rendered FPS or physical input latency**.
  Short MLP runs can finish before a sample: their delay fields are null, not zero.
- Cancellation is requested upon receiving progress for epoch 2. Record time until
  the result checkpoint and actual completed epochs. Message latency may allow the
  worker to start another epoch. Checkpoint consistency, not stopping at exactly 2,
  is the correctness requirement.
- Memory is sampled at start/end and timer ticks. Native process RSS includes the
  VM, all isolates and prior warmups. Chrome's optional performance.memory reports
  JS heap only. Neither is total allocated bytes or an exact peak. Do not compare
  these memory values as if they measured the same thing or attribute them solely
  to model weights. Engines may withhold the browser memory metric (null).
- CI uses Linux headless Flutter test hosts. These are not Android/iOS devices or
  production builds. No frame-time SLA follows from these numbers. Three runs do
  not establish confidence intervals or reliable p95 tail estimates for very small
  sample counts. Complete counts are included alongside every distribution.

## Recorded local Dart run

[Machine-readable native report](responsiveness-dart-native.json): Dart 3.11.5,
macOS arm64, 8 logical processors. Selected medians from this one invocation:

| Model / execution / batch | Wall training ms | Cancellation ms | Timer delay p95 ms |
| --- | ---: | ---: | ---: |
| CNN / automatic / 1 | 16.249 | 1.714 | 1.241 |
| CNN / cooperative / 1 | 10.677 | 0.145 | 0.601 |
| GRU / automatic / 1 | 15.287 | 2.188 | 0.799 |
| GRU / cooperative / 1 | 13.775 | 0.180 | 0.647 |

These tiny CPU workloads do not show that cooperative execution is universally
preferable: the isolate has startup/transport costs, but isolates protect a native
UI from larger work. Browser timer clamping changes the scheduling cost entirely.
Do not rank different model families from these differing workloads.

## Executor-step experiment

[Step timings](batch-latency.json) use a separate 128-sample MLP, hidden size 32,
8 epochs and batches 1/8/32. The initial step includes validation and a batch;
steps at later epoch boundaries also include evaluation. These are upper bounds
for executor scheduling units, not isolated gradient-only timings. Cold JIT and
GC are not controlled. The output labels those limits explicitly.

The experiment motivates isolating evaluation and profiling allocation in 0.4.0;
it does **not** prove that evaluation or any allocation site dominates wall time.
See the [roadmap and acceptance checks](../roadmap_0.4.0.md).

# 0.4.0 release scope

- Incremental preflight, training and validation evaluation, with original
  per-sample sum order, one final division and stable fused BCE/CCE losses.
- Optional SampleLossModel contract: external reductions remain atomic unless
  explicitly opted in; existing DifferentiableModel and v1 checkpoints remain.
- Typed trainer events, separate evaluation progress and configurable evaluation
  blocks, pause frequency and optional between-unit work-duration budget.
- Flutter controls, native/isolate and cooperative cancellation/replay coverage.
- Fixed-batch yield matrices, VM allocation counters/stacks and actual Linux and
  Chrome release-build frame probes with explicit measurement limits.
- Validation-only four-candidate forecasting experiment, preserving the published
  test; selected GRU still trails seasonal validation baselines.

[Implementation CI](https://github.com/kleberandrade/neural-engine/actions/runs/43975841654)
passed 125 Dart tests, minimum/stable SDKs, extension/hosted consumers, JavaScript
examples, Flutter tests, native/Chrome measurements, web build and package dry run.
[Performance evidence](https://github.com/kleberandrade/neural-engine/actions/runs/43975841544)
passed baseline/current allocation collection and release-frame capture with
per-platform checkpoint equality. See [permanent observations](benchmarks/scheduling_0.4.0.md).

The goal is scheduling control and evaluation responsiveness. The allocation
sample shows additional executor cost; no throughput improvement, optimizer
buffer optimization, worker pool or physical-phone frame guarantee is claimed.
The optional duration cannot interrupt one indivisible sample/batch operation.

Publication is pending the final tag workflow. The exact hosted consumer remains
pinned to 0.3.0 until the new artifact exists publicly.

# 0.4.0 plan: scheduling and measured allocation work

Status: planned, not implemented in 0.3.0. The scope follows the
[responsiveness protocol/results](benchmarks/responsiveness.md), current executor
boundaries and the [real-data examples](real_world.md), rather than adding models.

| Priority | Evidence / reason | Proposed work | Acceptance check |
| --- | --- | --- | --- |
| P1 | Browser batches yield, but dataset validation/evaluation still execute as full units | Incremental, chunked evaluation using explicit progress steps | Identical losses and checkpoints on each runtime; browser timer/input opportunity between chunks; cancellation never reports a partial epoch |
| P1 | Timers/RSS are proxies and do not expose allocation sites or physical frame jank | Capture allocation profiles and real Flutter integration traces on a named device plus Chrome release build | Archive exact build, hardware, dataset, profile method and raw measurements; report frame percentiles separately from event-loop delays |
| P2 | Every batch builds gradient/candidate vectors in the shared executor; actual allocation dominance remains unmeasured | Profile first, then reuse buffers at measured hot sites | No public aliasing of reused buffers; all finite-difference and exact-replay tests pass; compare allocated bytes and throughput using equal workloads with independent warmups |
| P2 | Tiny native workloads show visible isolate startup/transport cost | Measure dataset transfer and investigate a reusable worker lifecycle | Keep automatic native behavior explicit; no hidden size-based heuristic; test worker shutdown, repeated jobs, errors and cancellation |
| P2 | 1 ms timer samples can be absent for short jobs, and memory sampling misses peaks | Broaden workloads and repeats; separate startup vs steady state | Record sample counts, build mode, units and memory metric; avoid percentile claims from insufficient samples |
| P3 | The fixed GRU recipe loses to both temporal baselines | Add a new validation-led forecasting experiment, preserving the current reference example | Define selection protocol before new test evaluation; compare rolling/recursive modes explicitly; never tune the published 1959–1960 test |

## Proposed order

1. Establish device/release-build traces and allocation baseline.
2. Introduce incremental evaluation without changing arithmetic order or replay.
3. Optimize only measured allocation hot spots and retest all model families.
4. Re-run the same workloads and publish before/after observations with limits.

No new model family, GPU support, web workers, new checkpoint version or automatic
best-weight restoration is promised in this release plan. Such API choices need
separate design evidence. Existing v1 checkpoints must remain readable.

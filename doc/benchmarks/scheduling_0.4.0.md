# 0.4.0 scheduling and allocation evidence

## Fixed mathematics, different pauses

Run `dart run benchmark/yield_frequency.dart`. The shared implementation also
runs in Flutter native/Chrome tests via `test/yield_frequency_test.dart`.
CNN uses 128 samples; GRU uses 192. Every policy uses seed 42, batch size **4**,
8 epochs and the same dataset/order/optimizer. Policies vary batches between
pauses (1, 4, 16), evaluation block size (32, 8) and an optional 8 ms work budget.
There are three repetitions per policy. Every full serialized checkpoint must
match the first policy, including optimizer moments and absolute epoch state.

[Local native observations](yield-native-0.4.0.json), Dart 3.11.5 JIT/macOS arm64:

| Family | Batches / eval block / budget | Median wall ms (n=3) | Timer delay p95 ms (samples) |
| --- | --- | --- | --- |
| CNN | 1 / 32 / none | 57.713 | 0.929 (173) |
| CNN | 4 / 32 / none | 55.222 | 0.699 (147) |
| CNN | 16 / 32 / none | 53.874 | 2.317 (99) |
| CNN | 16 / 8 / none | 53.854 | 1.940 (94) |
| CNN | 16 / 8 / 8 ms | 54.963 | 2.397 (98) |
| GRU | 1 / 32 / none | 70.440 | 0.785 (199) |
| GRU | 4 / 32 / none | 67.232 | 0.458 (179) |
| GRU | 16 / 32 / none | 66.883 | 1.430 (133) |
| GRU | 16 / 8 / none | 65.366 | 1.740 (125) |
| GRU | 16 / 8 / 8 ms | 62.341 | 1.642 (124) |

All ten rows matched complete checkpoints exactly. These short runs expose a
throughput/latency tradeoff, not an optimal universal policy. Wall time has only
three samples; its p95 is effectively the maximum and is not a stable tail
estimate. Timer samples pool repetitions. The first policy includes more cold
work; policy order is fixed, not randomized. Compare within this run/runtime,
not across devices. Timers indicate event-loop opportunity, not frame timings.
The optional budget is checked between units and cannot interrupt one long unit.
No automatic size heuristic or default change follows from these measurements.

## Allocation baseline before buffer changes

`validation/profile_allocations.py` launches a separate VM service, warms each
workload, then records three reset/GC-separated measurements. The same
0.3-compatible `benchmark/profiling/allocation_harness.dart` is run against tag
v0.3.0 and the current checkout using separate package configurations. A flat
custom model separates executor/optimizer vectors from MLP forward/backward
caches. Results include parameters/loss, accumulated allocated bytes and live
class counters, plus allocation stacks traced in a separate pass. Application
classes are traced because the VM rejects allocation tracing of predefined
array classes. VM-service authentication endpoints are never archived.

Run the **Performance evidence** workflow to collect `allocation-evidence`.
[Successful capture](https://github.com/kleberandrade/neural-engine/actions/runs/43975841544)
on Dart 3.14.0 Linux x64 is archived in
[baseline counters/stacks](allocations-0.3.0-ci.json) and
[0.4.0 counters/stacks](allocations-0.4.0-ci.json). The full class/stack artifact is
`allocation-evidence` on that run. Parameters and losses match exactly in every
paired observation.

| Workload | Version | Median wall µs (n=3) | Median array accumulated bytes | Median total accumulated bytes |
| --- | --- | --- | --- | --- |
| Flat custom | 0.3.0 | 39,410 | 1,695,920 | 7,142,752 |
| Flat custom | 0.4.0 | 48,305 | 1,860,256 | 7,786,480 |
| MLP | 0.3.0 | 51,747 | 2,167,664 | 8,071,616 |
| MLP | 0.4.0 | 63,642 | 2,300,480 | 8,436,064 |

This run shows extra executor/iterator cost, not an allocation or throughput win.
Counters include VM/compiler activity, not only model-owned arrays; the profile
cannot assign all array bytes to optimizer workspaces. MLP traces identify
forward/evaluation and differentiation pass objects. No allocation optimization
is inferred from RSS or from these three process-level observations. Process RSS from earlier benchmarks is not allocated bytes and
cannot establish allocation sites. No reusable optimizer buffers or buffer
ownership API have been introduced without that evidence. Custom optimizer
states continue receiving fresh per-batch candidate/gradient vectors.

## Real release-mode frame probes

The same workflow builds `frame_probe_main.dart` in Flutter **release** mode.
A continuously animated interface runs a fixed CNN recipe (128 samples, batch
4, 160 epochs). Native Linux uses actual Flutter `FrameTiming` build/raster/total
callbacks on a named GitHub Actions virtual host, in automatic-isolate and
explicit cooperative modes. Chrome uses requestAnimationFrame intervals and an
external DevTools timeline trace; these are not native raster durations.

The workflow archives SDK/browser/CPU/image/source metadata, sample counts,
checkpoint equality, reports and compressed Chrome traces in
`release-frame-evidence`. Default (one batch / 32 evaluation samples) and
budgeted (16 batches / 8 samples / 8 ms) policies must produce identical
checkpoints within each platform. Cross-platform bitwise equality is not claimed.

[Successful release capture](https://github.com/kleberandrade/neural-engine/actions/runs/43975841544)
has [permanent summary distributions](release-frames-0.4.0-ci.json) and the full
`release-frame-evidence` artifact (reports with checkpoints, SDK/runner metadata
and compressed Chrome traces). Linux has 4 logical processors, Dart 3.14.0;
Chrome is 157.0.8103.50 / V8 15.7.112.23. Exact CPU/image/Flutter SDK metadata
belongs to the artifact, rather than an inferred physical device description.

| Host/mode | Policy | Wall ms | Samples | Total frame p95 ms / max ms | rAF p95 ms |
| --- | --- | --- | --- | --- | --- |
| Linux release / isolate | default | 2,374.186 | 89 | 42.993 / 1,736.776 | — |
| Linux release / isolate | budgeted | 2,362.699 | 143 | 41.265 / 58.479 | — |
| Linux release / cooperative | budgeted | 7,708.189 | 378 | 36.187 / 42.630 | — |
| Chrome release / cooperative | default | 33,897.599 | 2,034 | — | 16.8 |
| Chrome release / cooperative | budgeted | 19,524.900 | 1,171 | — | 16.7 |

These are one run per configuration in fixed order. The large native-default
maximum is retained; shader/renderer warmup, host contention and callback delivery
can affect it. Policy effects cannot be isolated from order with one repetition.
Headless rAF timestamps are presentation opportunities, not proof of rendered
raster completion. Reported native refresh rate was 0; no assumed display rate
is used to classify dropped frames. No phone FPS or speedup guarantee follows. These probes are not evidence of
physical mobile performance. A named physical device, refresh rate, thermal state
and release-build trace remain required before a phone frame-jank claim. Do not
turn timer or headless-CI observations into an FPS guarantee.

## Worker lifecycle

Automatic native execution remains a fresh dedicated isolate per task, with
request encoding/copying on the caller and explicit port cleanup at completion.
Short-workload end-to-end observations in the [0.3 protocol](responsiveness.md)
include startup/transport, not isolated transfer timings. A reusable worker pool
and a separate startup/steady-state transfer study remain deferred; no hidden
crossover heuristic or persistent worker lifecycle is exposed in 0.4.0.


## Flutter test hosts

[CI 43975841654](https://github.com/kleberandrade/neural-engine/actions/runs/43975841654)
passed the fixed-batch matrices on both [native test engine](yield-flutter-native-0.4.0.json)
and [Chrome](yield-flutter-chrome-0.4.0.json), including checkpoint equality in
all ten policy/family rows per runtime. These test-host timer observations remain
separate from the actual release-app frame measurements above.

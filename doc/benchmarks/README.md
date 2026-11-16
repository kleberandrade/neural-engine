# Local model measurements

Recorded on 2026-11-16. Reproduce from the repository root:

```sh
dart pub get
dart run benchmark/models_benchmark.dart > /tmp/neural-models.json
```

Runtime: 3.11.5 (stable) (Wed Apr 15 00:36:32 2026 -0700) on "macos_arm64". OS: macOS, 8 logical processors.

Five warmup training epochs precede 50 measured epochs. Differentiable models
use Adam (learning rate 0.01), batch size 8, shuffle and gradient norm limit 1;
the measured fit creates fresh optimizer state after warmup, while retaining
warmed model weights. SOM uses its default online learning/radius decay.
Seed 42. Training is one local JIT observation per workload, not a median.

Inference uses 50 warmup calls followed by five batches of 1,000 calls. The
reported median and range are per-call batch averages, not individual-request
latency percentiles. SOM inference means selecting the best matching unit.
Model bytes are compact UTF-8 inference JSON, excluding optimizer state,
checkpoint envelopes, runtime overhead and compression.

| Workload | Parameters | Samples | Train ms / 50 epochs | Median inference µs | Batch-average range µs | Model JSON bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| MLP XOR | 33 | 4 | 7.534 | 1.655 | 1.168–3.972 | 807 |
| CNN bars | 114 | 16 | 50.513 | 11.053 | 10.696–11.332 | 2684 |
| Dense autoencoder | 142 | 20 | 14.103 | 1.080 | 0.950–1.198 | 3025 |
| rnn | 55 | 24 | 42.315 | 3.843 | 3.480–3.973 | 1275 |
| lstm | 199 | 24 | 76.716 | 10.913 | 10.147–11.287 | 4152 |
| gru | 151 | 24 | 78.251 | 8.258 | 7.262–9.175 | 3185 |
| SOM colors | 108 | 48 | 18.332 | 0.217 | 0.211–0.252 | 2254 |

Raw observations and configuration: [local_models.json](local_models.json).
Workloads and parameter counts differ, so these values do not rank model
families or establish real-world quality, throughput or cross-device speed.
Timings include allocation and JIT effects; no confidence interval is inferred.
Repeat on the target device and runtime (JIT/AOT/web) before selecting a model.

The Flutter Checkpoints tab reports the full indented checkpoint UTF-8 size,
which includes Adam moments and metadata and is intentionally larger than the
inference-only figures above.

## Async responsiveness and real-data reference

See [protocol and observations](responsiveness.md), [fixed real-data results](real-world-results.json)
and the [0.4.0 plan](../roadmap_0.4.0.md). Event-loop delay is not rendered FPS;
sampled memory is not allocation profiling.


For the fixed-batch 0.4.0 yield matrix, allocation collector and release-frame
probe status, see [scheduling evidence](scheduling_0.4.0.md). Validation-only
forecast selection has a [separate frozen protocol](forecast-validation-protocol.txt).

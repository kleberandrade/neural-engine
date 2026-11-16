# Local model measurements

Recorded on 2026-11-16. Reproduce with `dart run benchmark/models_benchmark.dart`.

Runtime: 3.11.5 (stable) (Wed Apr 15 00:36:32 2026 -0700) on "macos_arm64". OS: macos.

Five warmup training epochs precede 50 measured epochs. Predictions use the median of five batches of 1000 calls after 50 warmup calls. Seed 42. Workloads, sample counts and parameter counts differ; this is not a controlled speed ranking or a real-world throughput guarantee.

| Workload | Parameters | Samples | Train ms / 50 epochs | Median prediction µs |
| --- | ---: | ---: | ---: | ---: |
| MLP XOR | 33 | 4 | 6.795 | 1.887 |
| CNN bars | 114 | 16 | 43.542 | 10.25 |
| Dense autoencoder | 142 | 20 | 11.893 | 0.933 |
| rnn | 55 | 24 | 31.309 | 2.681 |
| lstm | 199 | 24 | 61.601 | 9.072 |
| gru | 151 | 24 | 46.534 | 6.253 |
| SOM colors | 108 | 48 | 17.538 | — |

Raw observations: [local_models.json](local_models.json). SOM has a competitive fit/BMU API; this run reports its training duration only. Timings include allocations and this local JIT/runtime; no confidence interval or cross-device conclusion is inferred.

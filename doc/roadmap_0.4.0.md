# 0.4.0: scheduling and measured follow-up

Status: implemented locally, validation/publication pending. This replaces the
original plan with explicit delivery status; incomplete evidence is not a
completed performance claim. See [measurement protocol and observations](benchmarks/scheduling_0.4.0.md).

| Priority | Work | Status / acceptance |
| --- | --- | --- |
| P1 | Hold batch size fixed while varying yield frequency | Implemented. CNN/GRU, 3 repetitions, ten policies/family combinations; all complete checkpoints match in the local native report. Flutter native/Chrome CI capture pending. |
| P1 | Incremental preflight and training/validation evaluation | Implemented. Optional SampleLossModel, typed steps, ordered sum then one division, separate evaluation stream; custom reductions retain atomic fallback. Tests cover all supervised families, cancellation and complete optimizer state. |
| P1 | Explicit optional scheduling budget | Implemented between indivisible units; defaults unchanged. A budget cannot impose a hard frame deadline. |
| P1 | Actual release frame traces and allocation profiles | Collectors/workflow implemented; successful CI evidence pending. Native FrameTiming and Chrome traces are separate from timer observations. Physical-device capture remains outstanding. |
| P2 | Profile before reusing buffers | No buffer reuse shipped. Baseline/current allocation capture must succeed before selecting measured sites or changing extension ownership contracts. |
| P2 | Broader workloads/repetitions | Implemented fixed-batch CNN/GRU matrix with sample counts, units and checkpoint equality; no universal performance claim. |
| P2 | Startup/transfer study and reusable workers | Deferred. Fresh-isolate lifecycle stays explicit; port cleanup/error/cancellation tests remain. No pool or automatic crossover heuristic. |
| P3 | Validation-led forecasting, preserving the reference test | Implemented separate four-candidate experiment, rolling vs recursive validation and matching baselines. Published 1959–1960 test excluded; selected GRU still loses to seasonal validation baselines. No new test/generalization claim. |

## Release gates

1. Pass minimum/stable Dart, compiled JavaScript and Flutter interaction checks.
2. Capture successful allocation and native/Chrome release-frame CI results on
   the final source and archive metadata/raw reports with their limits.
3. Review bilingual guides, pub.dev dry run and v1 checkpoint compatibility.
4. Publish v0.4.0 through the existing tag/OIDC workflow, then validate the exact
   hosted artifact independently. Update the hosted consumer only after upload.

Physical-device evidence, measured buffer optimization and a reusable worker
lifecycle are explicit follow-ups, not silently delivered features. No new model
family, GPU support, Web Worker, checkpoint format or session early stopping is
introduced.

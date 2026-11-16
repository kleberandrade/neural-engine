# 0.2.0 release record

Published on November 16, 2026 under verified publisher `kleberandrade.dev`.

- [Hosted package](https://pub.dev/packages/neural_engine/versions/0.2.0)
- [GitHub release and tag](https://github.com/kleberandrade/neural-engine/releases/tag/v0.2.0)
- [Successful release workflow](https://github.com/kleberandrade/neural-engine/actions/runs/43935440907)
- Release commit: `840dc169983fdfaf8384d270e61ecf2dc2b33208`

The release includes the architecture refactor, model/evaluation features,
external contract validation and resumable persistence. Install with
`neural_engine: ^0.2.0`. Version 0.1.0 remains available.

## API review

- Existing public package imports and Dense/SOM/CNN version-1 JSON remain supported.
- Internal `lib/src` paths changed; direct implementation imports are unsupported.
- Dense/CNN/recurrent models implement shared prediction/parameter/gradient contracts.
- CNN adds optional validation, patience, minDelta and gradient clipping arguments.
- Recurrent models are many-to-one with zero state per sequence, full BPTT and reset-before GRU.
- No unimplemented family is presented as available.
- Fitted scalers have validated v1 JSON codecs.
- TrainingSession preserves Adam/SGD state across fixed-epoch checkpoints.
- Independent consumer exercises custom model/loss/optimizer and codecs.
- Core still has no runtime dependencies or Flutter imports.

## Verification before publication

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test example benchmark
dart analyze --fatal-infos
dart test
dart run example/neural_engine_example.dart
dart run example/regression.dart
dart run example/classification.dart
dart run example/som_colors.dart
dart run example/cnn_bars.dart
dart run example/autoencoder.dart
dart run example/recurrent_sequences.dart
dart run example/evaluation.dart
dart run example/custom_extensions.dart
dart run example/checkpoint.dart
dart doc
dart pub publish --dry-run
```

The CI matrix runs minimum/stable Dart, JavaScript examples, and Flutter
analysis/widget tests/web build. Inspect the actual run results for the release
commit. Local workload observations are in [benchmarks](benchmarks/README.md);
they are not a throughput promise or model-quality ranking.

In `example/flutter_lab`, verify all model tabs, drawing and narrow viewports.
Keep architecture diagrams, source map and tutorials synchronized with the final
code. Review packaged files and version availability on pub.dev immediately
before publishing. Do not overwrite an already published version.

## Publication result

All release jobs passed: minimum/stable Dart, Flutter, package validation,
archive generation and publication. The test suite contains 55 tests, with
additional external-consumer and Flutter checks.

The tag-scoped `.github/workflows/publish.yml` published `v0.2.0` using the
Dart-maintained workflow and temporary OIDC credentials. Pub.dev authorizes
push events from `kleberandrade/neural-engine` with tag pattern `v{{version}}`.
No personal Pub token is stored in the repository. Package ownership was
transferred to verified publisher `kleberandrade.dev` and confirmed after
publication.

The workflow currently targets only `v0.2.0`; review its tag trigger before
preparing a subsequent release. Published artifacts are immutable: changes to
this repository after the release require a new version to appear on pub.dev.

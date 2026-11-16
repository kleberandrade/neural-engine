# 0.2.0 release preparation

Source version 0.2.0 groups the architecture refactor and model/evaluation features.
This document prepares a manual release; it does not imply a pub.dev publication.

## API review

- Existing public package imports and Dense/SOM/CNN version-1 JSON remain supported.
- Internal `lib/src` paths changed; direct implementation imports are unsupported.
- Dense/CNN/recurrent models implement shared prediction/parameter/gradient contracts.
- CNN adds optional validation, patience, minDelta and gradient clipping arguments.
- Recurrent models are many-to-one with zero state per sequence, full BPTT and reset-before GRU.
- No unimplemented family is presented as available.
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

After a reviewed successful dry-run, the maintainer can publish through the
normal authorized `dart pub publish` flow and associate the verified publisher.
Only after confirming the published artifact should release metadata and
installation instructions be updated to that hosted version. This task prepares
the source and checks; no automatic publish/tag workflow is enabled.

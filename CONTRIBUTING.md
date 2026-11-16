# Contributing

Keep the core pure Dart and dependency-free. Follow the [source map](doc/architecture/structure.md) and [class diagrams](doc/architecture/class_diagrams.md). Do not put training lifecycle or Flutter rendering into numerical executors. Use the public library in tests.
Each new model family needs a runnable Dart example, a Flutter demonstration,
and a bilingual tutorial distinguishing implemented behavior from plans.
New numerical features require meaningful public-API tests, including finite
difference gradient verification where applicable. Validate boundary inputs.
Document API changes in English and Portuguese and update Unreleased notes.
Use semantic commits and focused changes.

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
dart compile js example/neural_engine_example.dart -o /tmp/neural_engine.js
dart pub publish --dry-run
```

Validate the Flutter lab independently with `flutter pub get`, `flutter analyze`
and `flutter test` in `example/flutter_lab`. The root analyzer excludes that
nested package so core contributors only need Dart; CI validates both packages.

Before publishing, review pub.dev name availability, package contents, docs and
CI. Confirm the version has not been published. First publish uses the verified
kleberandrade.dev publisher through the usual authorized pub.dev flow. This
repository does not publish automatically on push or tag. Create a release tag
only for a reviewed release, never just to test automation.

# Contributing

Keep the core pure Dart and dependency-free. Use the public library in tests.
New numerical features require meaningful public-API tests, including finite
difference gradient verification where applicable. Validate boundary inputs.
Document API changes in English and Portuguese and update Unreleased notes.
Use semantic commits and focused changes.

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test example
dart analyze --fatal-infos
dart test
dart run example/neural_engine_example.dart
dart run example/regression.dart
dart run example/classification.dart
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

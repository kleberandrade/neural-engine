# Hosted artifact validation

This standalone client deliberately pins `neural_engine: 0.3.0` from pub.dev.
It has no path or Git dependency and no overrides. Run it from this directory:

```sh
dart pub get
dart pub deps --json
dart analyze --fatal-infos
dart run main.dart
```

CI executes it on Dart 3.3.4 and stable before a new release can publish. The
program checks the lockfile source/version, runs a real temporary-file
checkpoint save/restore and compares full Adam/model state after 10 versus
4 + 6 epochs. It also exercises Dense, CNN, SOM, RNN, LSTM, GRU and both fitted
scaler JSON codecs. The temporary directory is removed on success or failure.

This verifies the existing released artifact independently of the working tree.
After publishing a new version, advance the exact pin and the expected lockfile
version in `main.dart`, then run CI again to validate that artifact. Keep a fixed
version here so a new release cannot silently validate itself through a path
substitution or resolve an unintended dependency range.

The 0.3.0 consumer also checks five model families with Adam and SGD in both
automatic (native isolate) and cooperative execution. It observes epoch/validation
progress, cancels, persists a real JSON checkpoint, restores and resumes, then
compares all weights/moments against synchronous training. The package-config
root and lockfile must both identify the exact hosted artifact, never the checkout.

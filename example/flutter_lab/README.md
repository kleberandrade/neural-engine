# Neural Engine Lab

An interactive Flutter XOR example with configurable hidden neurons and learning
rate, loss curve, decision surface and predictions. English UI.

```sh
flutter pub get
flutter test
flutter run -d chrome
```

Web runner files are bundled. Generate additional platform runners with
`flutter create --platforms=android,ios,macos .` as needed. On native platforms `compute` runs training in a worker isolate. On Flutter Web it runs on
the main event loop; this tiny example can briefly block during training. Core
training is synchronous. For larger web workloads use a dedicated web worker.

The plots refer to the last completed run. This is an educational XOR example,
not a benchmark or evidence of generalization to real datasets.

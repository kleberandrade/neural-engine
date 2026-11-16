# 0.3.0 release scope

The release combines portable asynchronous training with repeatable evaluation:

- Native isolate worker and cooperative browser batches sharing synchronous math.
- Epoch progress, optional validation metrics, safe cancellation and v1 checkpoint
  continuation for MLP/CNN/RNN/LSTM/GRU; dense autoencoders use the MLP path.
- Flutter Async training and Real data tabs, independent CLI examples and bilingual
  lifecycle/architecture/real-data documentation.
- Offline, attributed Iris and AirPassengers snapshots, training-only scalers,
  explicit reserved partitions and baselines, including the GRU's weaker result.
- Responsiveness probes for Dart and Flutter native/Chrome hosts, full machine-readable
  reports and limits distinguishing event-loop delays, frame times and memory metrics.
- [Evidence-led 0.4.0 plan](roadmap_0.4.0.md).

Local verification: 98 Dart tests; analyzer; all-family native/JavaScript replay;
real-data examples on native/JavaScript; dataset equality/hash checks; generated API
reference without warnings. Full Flutter tests, Chrome measurements, web build and
package publication validation run in CI. Publication and exact hosted 0.3.0
verification are recorded only after their workflows finish.

/// Immutable sample identities and data, shared by Dart and Flutter examples.
class DataPartition<I> {
  final List<int> ids;
  final List<I> inputs;
  final List<List<double>> targets;
  DataPartition(this.ids, this.inputs, this.targets);
}

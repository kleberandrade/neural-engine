import 'dart:math';
import 'package:neural_engine/neural_engine.dart';
import 'data_partition.dart';
import 'iris_data.dart';

class IrisDataset {
  static const labels = ['Iris-setosa', 'Iris-versicolor', 'Iris-virginica'];
  late final DataPartition<List<double>> train, validation, test;
  late final StandardScaler scaler;
  late final int uniqueRows;
  final int seed;
  IrisDataset({this.seed = 42}) {
    final rows =
        irisCsv.trim().split('\n').skip(1).map((s) => s.split(',')).toList();
    final seen = <String>{};
    final byClass = List.generate(3, (_) => <int>[]);
    for (var i = 0; i < rows.length; i++) {
      if (seen.add(rows[i].join(','))) {
        byClass[labels.indexOf(rows[i].last)].add(i);
      }
    }
    uniqueRows = seen.length;
    final trainIds = <int>[], validationIds = <int>[], testIds = <int>[];
    for (var label = 0; label < 3; label++) {
      final ids = byClass[label]..shuffle(Random(seed + label));
      final trainEnd = (ids.length * 0.6).floor();
      final validationEnd = trainEnd + (ids.length * 0.2).floor();
      trainIds.addAll(ids.take(trainEnd));
      validationIds.addAll(ids.sublist(trainEnd, validationEnd));
      testIds.addAll(ids.skip(validationEnd));
    }
    List<double> features(int id) =>
        rows[id].take(4).map(double.parse).toList();
    scaler = StandardScaler.fit(trainIds.map(features).toList());
    DataPartition<List<double>> partition(List<int> ids) => DataPartition(
        List.unmodifiable(ids),
        ids.map((id) => scaler.transform(features(id))).toList(),
        ids
            .map((id) => List.generate(
                3, (c) => c == labels.indexOf(rows[id].last) ? 1.0 : 0.0))
            .toList());
    train = partition(trainIds);
    validation = partition(validationIds);
    test = partition(testIds);
  }
}

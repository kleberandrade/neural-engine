// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';
import '../example/flutter_lab/lib/real_world/iris_data.dart';
import '../example/flutter_lab/lib/real_world/air_passengers_data.dart';
import '../example/flutter_lab/lib/real_world/iris_dataset.dart';
import '../example/flutter_lab/lib/real_world/passenger_dataset.dart';
import '../example/flutter_lab/lib/real_world/iris_experiment.dart';
import '../example/flutter_lab/lib/real_world/passenger_experiment.dart';
import '../example/flutter_lab/lib/real_world/forecast_validation.dart';

void main() {
  test('validation forecasts enforce causal rolling and recursive inputs', () {
    final original = ForecastValidation();
    final changed = original.observations.toList();
    for (var i = ForecastValidation.trainEnd; i < changed.length; i++) {
      changed[i] *= 2;
    }
    final altered = ForecastValidation(observations: changed);
    expect(original.observations, hasLength(120));
    expect(original.scaler.toJson(), altered.scaler.toJson());
    double infer(List<List<double>> input) => input.last.single + 0.1;
    final rolling = original.predict(infer, recursive: false);
    final changedRolling = altered.predict(infer, recursive: false);
    expect(rolling.first, changedRolling.first);
    expect(rolling[1], isNot(changedRolling[1]));
    expect(original.predict(infer, recursive: true),
        altered.predict(infer, recursive: true));
    expect(() => ForecastValidation(observations: [...changed, 100]),
        throwsArgumentError);
    expect(() => original.predict((_) => double.infinity, recursive: true),
        throwsStateError);
  });

  test('offline embedded datasets equal the pinned CSV observations', () {
    expect(irisCsv, File('example/data/iris.csv').readAsStringSync());
    expect(airPassengersCsv,
        File('example/data/air_passengers.csv').readAsStringSync());
    expect(irisCsv.trim().split('\n'), hasLength(151));
    expect(airPassengersCsv.trim().split('\n'), hasLength(145));
  });
  test(
      'Iris stratification has disjoint identities and no duplicate feature leakage',
      () {
    final data = IrisDataset();
    final partitions = [data.train, data.validation, data.test];
    expect(data.uniqueRows, 147);
    expect(partitions.expand((p) => p.ids).toSet(), hasLength(147));
    final seen = <String>{};
    for (final partition in partitions) {
      expect(partition.targets.map((t) => t.indexOf(1)).toSet(), {0, 1, 2});
      for (final input in partition.inputs) {
        expect(seen.add(jsonEncode(input)), isTrue);
      }
    }
    final rows =
        irisCsv.trim().split('\n').skip(1).map((s) => s.split(',')).toList();
    final training = data.train.ids
        .map((id) => rows[id].take(4).map(double.parse).toList())
        .toList();
    expect(data.scaler.toJson(), StandardScaler.fit(training).toJson());
    expect(IrisDataset().train.ids, data.train.ids);
  });
  test(
      'temporal windows never see current/future targets or fit future statistics',
      () {
    final data = PassengerDataset();
    expect(data.train.ids, [for (var i = 12; i < 96; i++) i]);
    expect(data.validation.ids, [for (var i = 96; i < 120; i++) i]);
    expect(data.test.ids, [for (var i = 120; i < 144; i++) i]);
    expect(
        data.scaler.toJson(),
        StandardScaler.fit(
                data.values.take(96).map((v) => [math.log(v)]).toList())
            .toJson());
    for (final partition in [data.train, data.validation, data.test]) {
      for (var i = 0; i < partition.ids.length; i++) {
        final id = partition.ids[i];
        expect(data.unscale(partition.targets[i].single),
            closeTo(data.values[id], 1e-9));
        for (var t = 0; t < 12; t++) {
          expect(data.unscale(partition.inputs[i][t].single),
              closeTo(data.values[id - 12 + t], 1e-9));
        }
      }
    }
    expect(data.months[data.test.ids.first], '1959-01');
  });
  test(
      'fixed real-data recipes produce finite held-out reports and honest baselines',
      () async {
    final iris = IrisExperiment();
    final irisResult = await AsyncTrainingTask.start(iris.request()).result;
    final report = iris.report(irisResult);
    expect(report['testAccuracy'], inInclusiveRange(0.0, 1.0));
    expect(report['baselineAccuracy'], inInclusiveRange(0.0, 1.0));
    expect(report['sampleRows'], hasLength(32));
    final passengers = PassengerExperiment();
    final result = await AsyncTrainingTask.start(passengers.request()).result;
    final metrics = passengers.report(result);
    expect((metrics['testMAEThousands']! as double).isFinite, isTrue);
    expect(metrics['seasonalMAEThousands'], closeTo(47.5833333333, 1e-8));
    expect(metrics['sampleRows'], hasLength(24));
    // No assertion that a neural model must beat a simple baseline.
  });
}

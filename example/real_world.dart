// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
import 'flutter_lab/lib/real_world/iris_experiment.dart';
import 'flutter_lab/lib/real_world/passenger_experiment.dart';
import 'flutter_lab/lib/real_world/real_world_experiment.dart';

Future<void> main() async {
  for (final experiment in <RealWorldExperiment>[
    IrisExperiment(),
    PassengerExperiment()
  ]) {
    final task = AsyncTrainingTask.start(experiment.request());
    final result = await task.result;
    print(
        const JsonEncoder.withIndent('  ').convert(experiment.report(result)));
  }
  print('Real-world examples passed');
}

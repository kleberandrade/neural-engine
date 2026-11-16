import 'dart:convert';
import 'dart:io';
import 'package:neural_engine/neural_engine.dart';

// Uses only 0.3.0 APIs so exactly the same workload can profile both versions.
Future<void> main(List<String> args) async {
  final kind = args.isEmpty ? 'mlp' : args.single;
  final inputs = List.generate(
      128, (i) => [i / 128, (i % 7) / 7, (i % 11) / 11, (i % 13) / 13]);
  final targets = inputs.map((x) => [x.reduce((a, b) => a + b) / 4]).toList();
  Map<String, Object?> run() {
    final DifferentiableModel<List<double>> model = kind == 'flat'
        ? FlatProbe(128)
        : NeuralNetwork(
            inputSize: 4,
            seed: 42,
            layers: [Dense(16, activation: Activation.tanh), Dense(1)]);
    final clock = Stopwatch()..start();
    final history = MiniBatchTrainer<List<double>>().fit(
        model: model,
        inputs: inputs,
        targets: targets,
        loss: const MeanSquaredError(),
        optimizer: Adam(learningRate: 0.01),
        epochs: 40,
        batchSize: 8,
        seed: 42);
    clock.stop();
    return {
      'kind': kind,
      'elapsedUs': clock.elapsedMicroseconds,
      'loss': history.losses.last,
      'parameters': model.parameters
    };
  }

  print('PROFILE_READY');
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line == 'warm') {
      run();
      run();
      print('PROFILE_WARMED');
    } else if (line == 'measure') {
      print('PROFILE_RESULT ${jsonEncode(run())}');
    } else if (line == 'quit') {
      break;
    }
  }
}

/// Isolates trainer/optimizer allocations from dense forward/backward caches.
class FlatProbe implements DifferentiableModel<List<double>> {
  List<double> _values;
  FlatProbe(int count) : _values = List.filled(count, 0);
  @override
  int get parameterCount => _values.length;
  @override
  List<double> get parameters => List.unmodifiable(_values);
  @override
  set parameters(List<double> values) => _values = List.of(values);
  @override
  List<double> predict(List<double> input) =>
      [_values.fold<double>(0, (s, v) => s + v / _values.length)];
  @override
  List<double> gradients(
      {required List<double> input,
      required List<double> target,
      required Loss loss}) {
    final d = loss.gradient(predict(input), target).single;
    return List.filled(parameterCount, d / parameterCount);
  }

  @override
  double evaluate(
      {required List<List<double>> inputs,
      required List<List<double>> targets,
      required Loss loss}) {
    var total = 0.0;
    for (var i = 0; i < inputs.length; i++) {
      total += loss.value(predict(inputs[i]), targets[i]);
    }
    return total / inputs.length;
  }
}

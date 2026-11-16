import 'dart:convert';
import 'package:neural_engine/neural_engine.dart';
// ignore: avoid_relative_lib_imports
import '../example/flutter_lab/lib/runners/async_demo_recipe.dart';

Future<void> check<I>(AsyncDemoRecipe recipe,
    DifferentiableModel<I> Function(Map<String, dynamic>) decoder) async {
  final sync = TrainingSession<I>.restore(
      checkpoint: recipe.initial, modelDecoder: decoder);
  final loss = switch (recipe.loss) {
    TrainingLoss.meanSquaredError => const MeanSquaredError(),
    TrainingLoss.binaryCrossEntropy => const BinaryCrossEntropy(),
    TrainingLoss.categoricalCrossEntropy => const CategoricalCrossEntropy(),
  };
  sync.fit(
      inputs: recipe.inputs.cast<I>(),
      targets: recipe.targets,
      loss: loss,
      epochs: 3,
      batchSize: recipe.batchSize,
      maxGradientNorm: 1);
  for (final frequency in [1, 4, 16]) {
    final task = AsyncTrainingTask.start(recipe.request(recipe.initial, 3,
        batchesPerYield: frequency,
        evaluationSamplesPerYield: 1,
        maxWorkDuration:
            frequency == 16 ? const Duration(milliseconds: 2) : null));
    final evaluations = <EvaluationProgress>[];
    final subscription = task.evaluationProgress.listen(evaluations.add);
    final result = await task.result;
    await subscription.cancel();
    if (jsonEncode(sync.checkpoint().toJson()) !=
        jsonEncode(result.checkpoint.toJson())) {
      throw StateError('${recipe.family}: policy $frequency diverged.');
    }
    if (evaluations.isEmpty ||
        evaluations.any((e) => !e.incremental) ||
        !evaluations.any((e) => e.phase == TrainingPhase.trainingPreflight) ||
        !evaluations
            .any((e) => e.phase == TrainingPhase.validationEvaluation) ||
        evaluations.any(
            (e) => e.samplesCompleted < e.totalSamples && e.loss != null)) {
      throw StateError(
          '${recipe.family}: invalid incremental progress transport.');
    }
    if (recipe
        .predictions(result.checkpoint)
        .expand((v) => v)
        .any((v) => !v.isFinite)) {
      throw StateError('Nonfinite prediction.');
    }
  }
  print(
      '${recipe.family}: exact synchronous/automatic checkpoint equality across yield policies');
}

Future<void> main() async {
  for (final family in ['MLP', 'CNN', 'RNN', 'LSTM', 'GRU', 'Autoencoder']) {
    final recipe = AsyncDemoRecipe(family);
    if (family == 'CNN') {
      await check<ImageTensor>(recipe, ConvolutionalNetwork.fromJson);
    } else if (['RNN', 'LSTM', 'GRU'].contains(family)) {
      await check<List<List<double>>>(recipe, RecurrentNetwork.fromJson);
    } else {
      await check<List<double>>(recipe, NeuralNetwork.fromJson);
    }
  }
  print('Async validation passed');
}

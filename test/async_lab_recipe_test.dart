import 'package:neural_engine/neural_engine.dart';
import 'package:test/test.dart';
// Exercise the same pure-Dart recipe used by the Flutter UI.
// ignore: avoid_relative_lib_imports
import '../example/flutter_lab/lib/runners/async_demo_recipe.dart';

void main() {
  for (final family in ['MLP', 'CNN', 'Autoencoder', 'RNN', 'LSTM', 'GRU']) {
    test('$family lab accepts its bounded recipe and rejects altered optimizer',
        () {
      final recipe = AsyncDemoRecipe(family);
      recipe.validateCheckpoint(recipe.initial);
      final changed = recipe.initial.toJson();
      changed['optimizer'] = Adam(learningRate: 0.5).toJson();
      expect(
          () => recipe.validateCheckpoint(TrainingCheckpoint.fromJson(changed)),
          throwsFormatException);
    });
  }
  test('same-shaped recurrent families cannot be relabeled', () {
    expect(
        () => AsyncDemoRecipe('GRU')
            .validateCheckpoint(AsyncDemoRecipe('RNN').initial),
        throwsFormatException);
  });
}

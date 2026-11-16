import 'package:neural_engine/neural_engine.dart';

/// Fixed recipe declared before inspecting the reserved test partition.
abstract interface class RealWorldExperiment {
  String get name;
  AsyncTrainingRequest request();
  Map<String, Object?> report(AsyncTrainingResult result);
}

int predictedClass(List<double> probabilities) {
  var best = 0;
  for (var i = 1; i < probabilities.length; i++) {
    if (probabilities[i] > probabilities[best]) best = i;
  }
  return best;
}

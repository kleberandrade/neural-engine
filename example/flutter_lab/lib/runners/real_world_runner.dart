import '../real_world/iris_experiment.dart';
import '../real_world/passenger_experiment.dart';
import '../real_world/real_world_experiment.dart';
export '../real_world/real_world_experiment.dart';

RealWorldExperiment realWorldExperiment(String name) =>
    name == 'Iris' ? IrisExperiment() : PassengerExperiment();

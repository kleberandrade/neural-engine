import '../optimizers/checkpoint_optimizer.dart';
import '../optimizers/adam.dart';
import '../optimizers/sgd.dart';

/// Built-in optimizer configuration dispatch; custom loaders stay application-owned.
class OptimizerCodec {
  static CheckpointOptimizer decode(Map<String, dynamic> json) =>
      switch (json['format']) {
        'neural_engine_adam' => Adam.fromJson(json),
        'neural_engine_sgd' => SGD.fromJson(json),
        _ => throw const FormatException('Unknown optimizer configuration.'),
      };
}

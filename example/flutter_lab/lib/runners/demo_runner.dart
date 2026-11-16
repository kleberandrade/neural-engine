import 'som_runner.dart';
import 'cnn_runner.dart';
import 'autoencoder_runner.dart';

Map<String, Object?> trainDemo(String name) => switch (name) {
      'som' => trainSom(),
      'cnn' => trainCnn(),
      'autoencoder' => trainAutoencoder(),
      _ => throw ArgumentError('Unknown demo')
    };

import '../activations/activation.dart';

/// Immutable specification; weights belong to each network, not this object.
class Dense {
  final int units;
  final Activation activation;

  Dense(this.units, {this.activation = Activation.linear}) {
    if (units <= 0) {
      throw ArgumentError.value(units, 'units', 'Must be positive.');
    }
  }
}

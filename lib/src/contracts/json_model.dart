/// A versioned JSON-compatible inference model. IO belongs to applications.
abstract interface class JsonModel {
  Map<String, Object?> toJson();
}

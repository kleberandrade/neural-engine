/// Strict helpers used only at persistence boundaries.
List<double> finiteVector(Object? value,
    {int? length, bool positive = false, bool nonnegative = false}) {
  if (value is! List ||
      value.isEmpty ||
      (length != null && value.length != length)) {
    throw const FormatException('Invalid vector dimensions.');
  }
  final result = <double>[];
  for (final v in value) {
    if (v is! num ||
        !v.isFinite ||
        (positive && v <= 0) ||
        (nonnegative && v < 0)) {
      throw const FormatException('Invalid finite vector value.');
    }
    result.add(v.toDouble());
  }
  return result;
}

void requireFormat(Map<String, dynamic> json, String format) {
  if (json['format'] != format || json['version'] != 1) {
    throw FormatException('Unsupported $format format/version.');
  }
}

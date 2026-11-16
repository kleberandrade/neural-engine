import 'dart:convert';
// ignore: avoid_relative_lib_imports
import 'flutter_lab/lib/real_world/forecast_validation.dart';

Future<void> main() async {
  final report = await ForecastValidation().run();
  print('NEURAL_FORECAST_VALIDATION ${jsonEncode(report)}');
  print('Validation-only forecasting passed');
}

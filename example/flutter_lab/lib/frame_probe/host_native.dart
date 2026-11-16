import 'dart:convert';
import 'dart:io';

Map<String, Object?> hostInfo() => {
      'host': 'native release app',
      'os': Platform.operatingSystem,
      'runtime': Platform.version,
      'logicalProcessors': Platform.numberOfProcessors
    };
String get policy => Platform.environment['NEURAL_FRAME_POLICY'] ?? 'default';
bool get cooperative =>
    Platform.environment['NEURAL_FRAME_EXECUTION'] == 'cooperative';
Future<void> waitForStart() async {}
void startPresentationProbe() {}
List<double> stopPresentationProbe() => [];
Future<void> finish(Map<String, Object?> report) async {
  final output = Platform.environment['NEURAL_FRAME_REPORT'];
  if (output == null) {
    throw StateError('Set NEURAL_FRAME_REPORT to an output JSON path.');
  }
  await File(output).writeAsString(jsonEncode(report));
  exit(0);
}

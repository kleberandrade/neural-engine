import 'dart:convert';
import 'dart:js_interop';

@JS('globalThis.neuralStartProbe')
external JSBoolean? get _start;
@JS('globalThis.neuralFrameReport')
external set _report(JSString value);
@JS('navigator.userAgent')
external String get _agent;
@JS('requestAnimationFrame')
external JSNumber _requestFrame(JSFunction callback);
bool _active = false;
final _intervals = <double>[];
Map<String, Object?> hostInfo() => {
      'host': 'Chrome release app',
      'runtime': 'dart2js release',
      'userAgent': _agent
    };
String get policy => Uri.base.queryParameters['policy'] ?? 'default';
bool get cooperative => false;
Future<void> waitForStart() async {
  while (_start?.toDart != true) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void startPresentationProbe() {
  _active = true;
  _intervals.clear();
  double? previous;
  late JSFunction callback;
  callback = ((JSNumber timestamp) {
    if (!_active) return;
    final now = timestamp.toDartDouble;
    if (previous != null) _intervals.add(now - previous!);
    previous = now;
    _requestFrame(callback);
  }).toJS;
  _requestFrame(callback);
}

List<double> stopPresentationProbe() {
  _active = false;
  return List.of(_intervals);
}

Future<void> finish(Map<String, Object?> report) async {
  _report = jsonEncode(report).toJS;
}

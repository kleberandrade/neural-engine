import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('performance.memory')
external JSObject? get _memory;
@JS('navigator.userAgent')
external String get _userAgent;
int? memoryBytes() {
  try {
    return _memory?.getProperty<JSNumber>('usedJSHeapSize'.toJS).toDartInt;
  } catch (_) {
    return null;
  }
}

Map<String, Object?> runtimeInfo() {
  String? agent;
  try {
    agent = _userAgent;
  } catch (_) {
    agent = null;
  }
  return {
    'runtime': 'JavaScript',
    'userAgent': agent,
    'memoryMetric': 'performance.memory.usedJSHeapSize, when exposed'
  };
}

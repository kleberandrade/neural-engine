// The Flutter web compiler serves package libraries, so the shared implementation
// lives inside the example package. It remains pure Dart, without Flutter imports.
// ignore_for_file: avoid_relative_lib_imports
import '../example/flutter_lab/lib/benchmarks/responsiveness.dart' as benchmark;
export '../example/flutter_lab/lib/benchmarks/responsiveness.dart'
    show runResponsiveness;

Future<void> main() => benchmark.main();

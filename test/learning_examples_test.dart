import 'dart:io';
import 'package:test/test.dart';
// The learning content is pure Dart and shares the real public API examples.
// ignore: avoid_relative_lib_imports
import '../example/flutter_lab/lib/content/learning_content.dart';

void main() {
  for (final lesson in lessons) {
    test('Learn ${lesson.id}: displayed public API example compiles and runs',
        () async {
      final directory = Directory.systemTemp.createTempSync('neural-learn-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/example.dart');
      file.writeAsStringSync(
          "import 'package:neural_engine/neural_engine.dart';\nvoid main() {\n${lesson.code}\n}\n");
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        file.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });
  }
}

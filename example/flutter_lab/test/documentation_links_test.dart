import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/content/lab_links.dart';
import 'package:neural_engine_lab/content/lab_examples.dart';
import 'package:neural_engine_lab/content/learning_content.dart';

void main() {
  test('integrated lessons point to existing guides and implemented presets',
      () {
    for (final path in documentationPaths) {
      expect(File('../../$path').existsSync(), isTrue, reason: path);
      expect(Uri.parse(documentationUrl(path)).host, 'github.com');
    }
    for (final lesson in lessons) {
      expect(
          labExamples.any((example) => example.id == lesson.exampleId), isTrue);
      for (final suffix in ['', '.pt-BR']) {
        expect(
            File('../../doc/${lesson.source}$suffix.md').existsSync(), isTrue);
      }
    }
    expect(File('../../pubspec.yaml').readAsStringSync(),
        contains('version: $coreVersion'));
  });
}

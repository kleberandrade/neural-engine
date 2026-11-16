// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/main.dart';

void main() {
  testWidgets('lab trains XOR and renders predictions', (tester) async {
    await tester.pumpWidget(const NeuralLab());
    expect(find.text('Train network'), findsOneWidget);
    await tester.tap(find.text('Train network'));
    await tester.runAsync(() async {
      // compute uses a real isolate on native platforms.
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Final binary cross entropy:'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

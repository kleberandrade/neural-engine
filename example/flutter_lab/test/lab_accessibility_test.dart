// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine/neural_engine.dart';
import 'package:neural_engine_lab/widgets/drawing_classifier.dart';
import 'package:neural_engine_lab/widgets/loss_chart.dart';

void main() {
  testWidgets(
    'loss curves expose numerical training and validation summaries',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LossChart(training: [0.8, 0.2], validation: [0.9, 0.3]),
          ),
        ),
      );
      expect(
        find.text('Training 0.80000 → 0.20000 · Validation 0.90000 → 0.30000'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Loss curve over 2 completed epochs')),
        findsOneWidget,
      );
      final chart = find.descendant(
        of: find.byType(LossChart),
        matching: find.byType(CustomPaint),
      );
      expect(tester.getSize(chart).width, greaterThan(300));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('drawing pixels work with keyboard and have row/column labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final model = ConvolutionalNetwork(
      inputHeight: 6,
      inputWidth: 6,
      seed: 42,
      layers: [
        Conv2D(filters: 4, padding: ConvolutionPadding.same),
        MaxPool2D(),
      ],
      denseLayers: [Dense(2, activation: Activation.softmax)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DrawingClassifier(model: model)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final pixel = find.bySemanticsLabel('Pixel row 1, column 1');
    expect(tester.getSemantics(pixel), isSemantics(isToggled: true));
    await tester.tap(find.text('Classify drawing'));
    await tester.pump();
    expect(find.textContaining('Drawing probabilities'), findsOneWidget);
    await tester.tap(find.text('Clear drawing'));
    await tester.pump();
    expect(tester.getSemantics(pixel), isSemantics(isToggled: false));
    expect(find.textContaining('Drawing probabilities'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

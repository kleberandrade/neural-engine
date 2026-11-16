// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/main.dart';

Future<void> waitForResult(WidgetTester tester, Finder result) async {
  for (var i = 0; i < 300; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    if (result.evaluate().isNotEmpty) return;
  }
  fail('Training result did not arrive within 15 seconds.');
}

void main() {
  testWidgets('MLP trains XOR and renders predictions', (tester) async {
    await tester.pumpWidget(const NeuralLab());
    await tester.tap(find.text('Train network'));
    await waitForResult(
        tester, find.textContaining('Final binary cross entropy:'));
    expect(tester.takeException(), isNull);
  });

  for (final name in ['som', 'cnn', 'autoencoder']) {
    testWidgets('$name trains and renders its own model result',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const NeuralLab());
      await tester.tap(find
          .text(name == 'autoencoder' ? 'Autoencoder' : name.toUpperCase()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('train-$name')));
      await waitForResult(tester, find.byKey(ValueKey('result-$name')));
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
      if (name == 'cnn') {
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('classify-drawing')), 250,
            scrollable: find
                .descendant(
                    of: find.byType(ListView).last,
                    matching: find.byType(Scrollable))
                .first);
        await tester.tap(find.byKey(const ValueKey('classify-drawing')));
        await tester.pump();
        expect(find.textContaining('Drawing probabilities'), findsOneWidget);
      }
      // Inspect the lower visualizations, including on a narrow viewport.
      tester.view.physicalSize = const Size(390, 844);
      await tester.pump();
      await tester.drag(find.byType(ListView).last, const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('sequence comparison trains RNN LSTM and GRU', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const NeuralLab());
    await tester.tap(find.text('Sequences'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('train-sequence')));
    await waitForResult(tester, find.byKey(const ValueKey('result-sequence')));
    expect(find.text('lstm'), findsWidgets);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

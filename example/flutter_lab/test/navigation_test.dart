import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/main.dart';
import 'widget_test.dart' show waitForResult;

void main() {
  testWidgets('trained results survive changing experiments and mobile layout',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const NeuralLab());
    await tester.tap(find.text('Train network'));
    await waitForResult(
        tester, find.textContaining('Final binary cross entropy:'));
    await tester.tap(find.text('Real data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MLP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Final binary cross entropy:'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-experiment')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile navigation works at 320 px and with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const NeuralLab());
    await tester.tap(find.byKey(const ValueKey('mobile-experiment')));
    await tester.pumpAndSettle();
    final real = find.text('Real data · Evaluate beyond training').last;
    await tester.ensureVisible(real);
    await tester.tap(real);
    await tester.pumpAndSettle();
    expect(find.text('Good fit is a start.\nEvidence goes further.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-experiment')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

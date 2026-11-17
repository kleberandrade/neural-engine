import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/pages/real_world_page.dart';
import 'widget_test.dart' show waitForResult;

void main() {
  testWidgets(
      'Iris trains offline and renders held-out metrics on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: RealWorldPage())));
    await tester.runAsync(
        () => tester.tap(find.byKey(const ValueKey('real-world-train'))));
    await waitForResult(
        tester, find.byKey(const ValueKey('real-world-result')));
    await tester.scrollUntilVisible(find.text('Test accuracy'), 250,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('real-world-scroll')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Test accuracy'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

import 'scroll_helpers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine_lab/pages/checkpoint_page.dart';
import 'widget_test.dart' show waitForResult;

Future<void> reveal(WidgetTester tester, String key, double delta) =>
    revealControl(tester, 'checkpoint-scroll', key, delta);

void main() {
  testWidgets('checkpoint JSON survives recreating the page and resumes',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: CheckpointPage())));
    await tester.tap(find.byKey(const ValueKey('checkpoint-start')));
    await waitForResult(tester, find.text('Completed epochs: 40'));
    await tester.pumpAndSettle();
    await reveal(tester, 'checkpoint-json', -250);
    final saved = tester
        .widget<TextField>(find.byKey(const ValueKey('checkpoint-json')))
        .controller!
        .text;
    expect(saved, contains('optimizerState'));
    // Dispose the entire page: loading must not depend on retained model objects.
    await tester.pumpWidget(const SizedBox());
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: CheckpointPage())));
    await reveal(tester, 'checkpoint-json', -250);
    await tester.enterText(
        find.byKey(const ValueKey('checkpoint-json')), saved);
    await reveal(tester, 'checkpoint-load', 250);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkpoint-load')));
    await waitForResult(tester, find.text('Completed epochs: 40'));
    await tester.pumpAndSettle();
    await reveal(tester, 'checkpoint-resume', 250);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checkpoint-resume')).hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checkpoint-resume')));
    await waitForResult(tester, find.text('Completed epochs: 100'));
    await tester.pumpAndSettle();
    expect(find.text('Full model + Adam state matches uninterrupted run: true'),
        findsOneWidget);
    expect(find.text('Maximum prediction difference: 0.0'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await reveal(tester, 'checkpoint-json', -250);
    await tester.enterText(find.byKey(const ValueKey('checkpoint-json')), '{}');
    await reveal(tester, 'checkpoint-load', 250);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkpoint-load')));
    await waitForResult(tester, find.byKey(const ValueKey('checkpoint-error')));
    await reveal(tester, 'checkpoint-result', 250);
    expect(find.text('Completed epochs: 100'), findsOneWidget);
  });
}

import 'dart:convert';

import 'package:neural_engine_lab/runners/async_demo_recipe.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_engine/neural_engine.dart';
import 'package:neural_engine_lab/pages/async_training_page.dart';

import 'widget_test.dart' show waitForResult;

Future<void> reveal(WidgetTester tester, String key, double delta) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump();
    if (find.byKey(ValueKey(key)).hitTestable().evaluate().isNotEmpty) return;
    final origin =
        tester.getTopLeft(find.byKey(const ValueKey('async-scroll'))) +
            const Offset(8, 100);
    await tester.dragFrom(origin, Offset(0, delta));
    await tester.pump();
  }
  fail('Could not reveal $key');
}

Widget page() => const MaterialApp(
    home: Scaffold(
        body: AsyncTrainingPage(execution: TrainingExecution.cooperative)));

void main() {
  testWidgets('interact, cancel, recreate, load, resume and compare',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(page());
    await reveal(tester, 'async-start', -250);
    await tester
        .runAsync(() => tester.tap(find.byKey(const ValueKey('async-start'))));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('async-start')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const ValueKey('async-interact')));
    await tester.pump();
    expect(find.text('UI interactions: 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('async-cancel')));
    await waitForResult(tester, find.textContaining('Cancelled at epoch'));
    await tester.pump();
    await reveal(tester, 'async-json', -250);
    final json = tester
        .widget<TextField>(find.byKey(const ValueKey('async-json')))
        .controller!
        .text;
    expect(json, contains('optimizerState'));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    await reveal(tester, 'async-json', -250);
    await tester.enterText(find.byKey(const ValueKey('async-json')), json);
    await reveal(tester, 'async-load', 250);
    await tester.tap(find.byKey(const ValueKey('async-load')));
    await tester.pump();
    await reveal(tester, 'async-resume', 250);
    await tester
        .runAsync(() => tester.tap(find.byKey(const ValueKey('async-resume'))));
    await waitForResult(tester, find.text('Completed at epoch 100'));
    await reveal(tester, 'async-compare', 250);
    await tester.runAsync(
        () => tester.tap(find.byKey(const ValueKey('async-compare'))));
    await waitForResult(tester, find.text('Exact checkpoint match: true'));
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    await reveal(tester, 'async-json', -250);
    await tester.enterText(find.byKey(const ValueKey('async-json')), '{}');
    await reveal(tester, 'async-load', 250);
    await tester.tap(find.byKey(const ValueKey('async-load')));
    await tester.pump();
    expect(find.byKey(const ValueKey('async-error')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pause retains a checkpoint; reset clears the experiment',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(page());
    expect(find.textContaining('Adam · learning rate 0.02'), findsOneWidget);
    await reveal(tester, 'async-start', -250);
    await tester
        .runAsync(() => tester.tap(find.byKey(const ValueKey('async-start'))));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('async-pause')));
    await waitForResult(tester, find.textContaining('Paused at epoch'));
    await reveal(tester, 'async-resume', 250);
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('async-resume')))
            .onPressed,
        isNotNull);
    await tester
        .runAsync(() => tester.tap(find.byKey(const ValueKey('async-resume'))));
    await waitForResult(tester, find.text('Completed at epoch 100'));
    await reveal(tester, 'async-reset', 250);
    await tester.tap(find.byKey(const ValueKey('async-reset')));
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('async-resume')))
            .onPressed,
        isNull);
    await reveal(tester, 'async-json', -250);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('async-json')))
            .controller!
            .text,
        isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'loading rejects a recurrent checkpoint labeled as another family',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(page());
    await reveal(tester, 'async-json', -250);
    await tester.enterText(
        find.byKey(const ValueKey('async-json')),
        jsonEncode({
          'format': 'neural-engine-async-lab',
          'version': 1,
          'family': 'GRU',
          'goal': 100,
          'checkpoint': AsyncDemoRecipe('LSTM').initial.toJson(),
        }));
    await reveal(tester, 'async-load', 250);
    await tester.tap(find.byKey(const ValueKey('async-load')));
    await tester.pump();
    expect(find.byKey(const ValueKey('async-error')), findsOneWidget);
    expect(find.textContaining('Loaded at epoch'), findsNothing);
  });

  testWidgets('disposing an active page safely cancels its task',
      (tester) async {
    await tester.pumpWidget(page());
    await reveal(tester, 'async-start', -250);
    await tester
        .runAsync(() => tester.tap(find.byKey(const ValueKey('async-start'))));
    await tester.pumpWidget(const SizedBox());
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

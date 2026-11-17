import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neural_engine_lab/app.dart';
import 'package:neural_engine_lab/pages/mlp_page.dart';
import 'widget_test.dart' show waitForResult;

void main() {
  testWidgets(
      'language, Learn and Examples preserve state until a preset is loaded',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(NeuralLab(preferences: preferences));
    await tester.tap(find.text('Train network'));
    await waitForResult(
        tester, find.textContaining('Final binary cross entropy:'));
    await tester.tap(find.byKey(const ValueKey('language-pt')));
    await tester.pumpAndSettle();
    expect(preferences.getString('neural-lab-language'), 'pt-BR');
    expect(find.text('Laboratório'), findsOneWidget);
    expect(
        find.textContaining('Entropia cruzada binária final:'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-1')));
    await tester.pumpAndSettle();
    expect(
        find.text('Entenda o modelo.\nDepois, experimente.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-0')));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Entropia cruzada binária final:'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('section-2')));
    await tester.pumpAndSettle();
    final preset = find.byKey(const ValueKey('example-xor-small'));
    await tester.ensureVisible(preset);
    await tester.tap(preset);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Slider>(find
                .descendant(
                    of: find.byType(MlpPage), matching: find.byType(Slider))
                .first)
            .value,
        2);
    expect(
        find.textContaining('Entropia cruzada binária final:'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(NeuralLab(preferences: preferences));
    await tester.pumpAndSettle();
    expect(find.text('Laboratório'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile navbar and language menu accept keyboard activation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const NeuralLab());
    Focus.of(tester.element(find.text('Learn'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Understand the model.\nThen make it yours.'),
        findsOneWidget);
    tester
        .widget<IconButton>(find.byKey(const ValueKey('language-pt')))
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Aprender'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('language-pt'))).width,
        greaterThanOrEqualTo(48));
    expect(find.byKey(const ValueKey('documentation-link')), findsOneWidget);
    expect(find.byKey(const ValueKey('github-link')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

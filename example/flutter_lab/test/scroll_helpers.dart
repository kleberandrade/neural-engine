import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Find a control in the outer list without scrolling an embedded JSON editor.
Future<void> revealControl(
    WidgetTester tester, String listKey, String key, double delta) async {
  final list = find.byKey(ValueKey(listKey));
  final target = find.byKey(ValueKey(key));
  var movement = delta;
  for (var i = 0; i < 50; i++) {
    await tester.pump();
    if (target.hitTestable().evaluate().isNotEmpty) return;
    if (target.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await tester.pump();
      if (target.hitTestable().evaluate().isNotEmpty) return;
    }
    final outer = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)).first);
    final previous = outer.position.pixels;
    await tester.dragFrom(
        tester.getTopLeft(list) + const Offset(8, 100), Offset(0, movement));
    await tester.pump();
    if ((outer.position.pixels - previous).abs() < 1) movement = -movement;
  }
  fail('Could not reveal $key in $listKey');
}

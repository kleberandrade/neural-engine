import 'package:material_ui/material_ui.dart';
import 'translations.dart';

enum LabLanguage { english, portuguese }

class LabCopyScope extends InheritedWidget {
  final LabLanguage language;
  final ValueChanged<LabLanguage> onChanged;
  const LabCopyScope(
      {super.key,
      required this.language,
      required this.onChanged,
      required super.child});
  static LabCopyScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LabCopyScope>();
  @override
  bool updateShouldNotify(LabCopyScope oldWidget) =>
      language != oldWidget.language;
}

String tr(BuildContext context, String value) => translate(
    value, LabCopyScope.maybeOf(context)?.language == LabLanguage.portuguese);
String bilingual(BuildContext context, String english, String portuguese) =>
    LabCopyScope.maybeOf(context)?.language == LabLanguage.portuguese
        ? portuguese
        : english;

/// All visible UI copy uses the same inherited locale without owning model state.
class LabText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  const LabText(this.data,
      {super.key,
      this.style,
      this.textAlign,
      this.overflow,
      this.maxLines,
      this.softWrap});
  @override
  Widget build(BuildContext context) => Text(tr(context, data),
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap);
}

import '../content/lab_examples.dart';
import '../l10n/lab_copy.dart';
import 'package:material_ui/material_ui.dart';

const labBackground = Color(0xFF0B111C);
const labSurface = Color(0xFF131E2E);
const labBorder = Color(0xFF2A394E);
const labMuted = Color(0xFFA4B3C8);
const labAccent = Color(0xFF8DE0CC);
const labViolet = Color(0xFFAFBBFF);

class LabPanel extends StatelessWidget {
  final String title;
  final String? eyebrow, subtitle;
  final Widget child;
  final Widget? trailing;
  const LabPanel(
      {super.key,
      required this.title,
      required this.child,
      this.eyebrow,
      this.subtitle,
      this.trailing});
  @override
  Widget build(BuildContext context) => Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
          width: double.infinity,
          child: Material(
            color: labSurface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: labBorder)),
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        LabText(eyebrow!,
                            style: const TextStyle(
                                color: labAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2)),
                        const SizedBox(height: 8),
                      ],
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Semantics(
                                    header: true,
                                    child: LabText(title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge))),
                            if (trailing != null) trailing!,
                          ]),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        LabText(subtitle!,
                            style: const TextStyle(
                                color: labMuted, fontSize: 13, height: 1.5))
                      ],
                      const SizedBox(height: 22),
                      child,
                    ])),
          )));
}

class LabHeader extends StatelessWidget {
  final String kicker, title, description;
  final List<Widget> tags;
  const LabHeader(
      {super.key,
      required this.kicker,
      required this.title,
      required this.description,
      this.tags = const []});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LabText(kicker.toUpperCase(),
              style: const TextStyle(
                  color: labAccent,
                  letterSpacing: 2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Semantics(
              header: true,
              child: LabText(title,
                  style: Theme.of(context).textTheme.headlineLarge)),
          const SizedBox(height: 12),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: LabText(description,
                  style: const TextStyle(
                      color: labMuted, fontSize: 15, height: 1.65))),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(spacing: 8, runSpacing: 8, children: tags)
          ],
        ]),
      );
}

class LabTag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const LabTag(this.text, {super.key, this.color = labMuted, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: .2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6)
          ],
          Flexible(
              child: LabText(text,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600))),
        ]),
      );
}

class LabMetric extends StatelessWidget {
  final String label, value;
  final String? detail;
  final Color color;
  const LabMetric(
      {super.key,
      required this.label,
      required this.value,
      this.detail,
      this.color = labAccent});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LabText(label, style: const TextStyle(color: labMuted, fontSize: 12)),
        const SizedBox(height: 8),
        LabText(value,
            style: TextStyle(
                color: color,
                fontSize: 29,
                fontWeight: FontWeight.w600,
                letterSpacing: -1)),
        if (detail != null) ...[
          const SizedBox(height: 4),
          LabText(detail!,
              style: const TextStyle(color: labMuted, fontSize: 11))
        ],
      ]);
}

class LabNotice extends StatelessWidget {
  final String text;
  final IconData icon;
  const LabNotice(this.text, {super.key, this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: labMuted, size: 17),
          const SizedBox(width: 10),
          Expanded(
              child: LabText(text,
                  style: const TextStyle(
                      color: labMuted, height: 1.6, fontSize: 12))),
        ]),
      );
}

class LabEmpty extends StatelessWidget {
  final String title, description;
  final IconData icon;
  const LabEmpty(
      {super.key,
      required this.title,
      required this.description,
      this.icon = Icons.show_chart_rounded});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: labViolet.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(18)),
                  child: Icon(icon, size: 32, color: labViolet)),
              const SizedBox(height: 18),
              LabText(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: LabText(description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: labMuted, fontSize: 13, height: 1.6))),
            ])),
      );
}

/// Stacks on phones and leaves the result panel room to breathe on desktops.
class LabColumns extends StatelessWidget {
  final Widget controls, results;
  const LabColumns({super.key, required this.controls, required this.results});
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        if (bounds.maxWidth < 860) {
          return Column(
              children: [controls, const SizedBox(height: 20), results]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 300, child: controls),
          const SizedBox(width: 22),
          Expanded(child: results),
        ]);
      });
}

class LabNavigation extends InheritedWidget {
  final ValueChanged<int> select;
  final LabExample? example;
  final int revision;
  const LabNavigation(
      {super.key,
      required this.select,
      required super.child,
      this.example,
      this.revision = 0});
  static LabNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LabNavigation>();
  @override
  bool updateShouldNotify(LabNavigation oldWidget) =>
      select != oldWidget.select || revision != oldWidget.revision;
}

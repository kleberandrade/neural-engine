import 'package:material_ui/material_ui.dart';
import '../content/lab_examples.dart';
import '../l10n/lab_copy.dart';
import '../widgets/lab_design.dart';

class ExamplesPage extends StatelessWidget {
  final ValueChanged<LabExample> onExample;
  const ExamplesPage({super.key, required this.onExample});
  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const LabHeader(
                kicker: 'Examples / Ready-to-run recipes',
                title: 'Start with a question.\nLoad a real experiment.',
                description:
                    'These presets use the actual data generators and runners in this repository. Loading configures the workspace; training still starts only when you press its button.',
                tags: [
                  LabTag('Deterministic recipes', color: labAccent),
                  LabTag('No automatic training'),
                  LabTag('Learn by changing one setting')
                ]),
            LayoutBuilder(builder: (context, bounds) {
              final columns = bounds.maxWidth >= 1050
                  ? 3
                  : bounds.maxWidth >= 650
                      ? 2
                      : 1;
              final width = (bounds.maxWidth - 20 * (columns - 1)) / columns;
              return Wrap(spacing: 20, runSpacing: 20, children: [
                for (final example in labExamples)
                  SizedBox(
                      width: width,
                      child: LabPanel(
                          eyebrow: 'READY-TO-RUN',
                          title: example.title,
                          subtitle: example.description,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LabTag(example.parameters, color: labViolet),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                    key: ValueKey('example-${example.id}'),
                                    onPressed: () => onExample(example),
                                    icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18),
                                    label: const LabText('Load example')),
                              ])))
              ]);
            }),
            const LabNotice(
                'Changing sections or languages preserves the active experiment. Loading a preset is an explicit configuration change; finish or cancel an active run before replacing its recipe.'),
          ])));
}

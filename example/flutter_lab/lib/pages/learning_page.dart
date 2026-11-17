import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../content/learning_content.dart';
import '../content/lab_examples.dart';
import '../content/lab_links.dart';
import '../l10n/lab_copy.dart';
import '../widgets/lab_design.dart';

class LearningPage extends StatefulWidget {
  final ValueChanged<LabExample> onExample;
  const LearningPage({super.key, required this.onExample});
  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) {
    final lesson = lessons[_selected];
    String copy(LessonCopy pair) => bilingual(context, pair.$1, pair.$2);
    final pt =
        LabCopyScope.maybeOf(context)?.language == LabLanguage.portuguese;
    final source = 'doc/${lesson.source}${pt ? '.pt-BR' : ''}.md';
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
                key: const ValueKey('learn-scroll'),
                padding: const EdgeInsets.all(24),
                children: [
                  const LabHeader(
                      kicker: 'Learn / Neural Engine 0.4.0',
                      title: 'Understand the model.\nThen make it yours.',
                      description:
                          'A practical guide to the models implemented in this engine. Read the idea, interpret the math and open a real experiment.',
                      tags: [
                        LabTag('7 model families', color: labViolet),
                        LabTag('Real source documentation'),
                        LabTag('5 practical exercises')
                      ]),
                  LabPanel(
                      eyebrow: 'START HERE',
                      title: 'The learning loop',
                      child: const LabText(
                          'Data provides examples. A model produces predictions. A loss measures error. An optimizer changes parameters. Validation checks what the training curve alone cannot tell you.',
                          style: TextStyle(color: labMuted, height: 1.7))),
                  const SizedBox(height: 20),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < lessons.length; i++)
                      ChoiceChip(
                          label: LabText(copy(lessons[i].title)),
                          selected: _selected == i,
                          onSelected: (_) => setState(() => _selected = i))
                  ]),
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: 'FUNDAMENTALS & ALGORITHMS',
                      title: copy(lesson.title),
                      subtitle: copy(lesson.summary),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabText(copy(lesson.explanation),
                                style: const TextStyle(height: 1.8)),
                            const SizedBox(height: 24),
                            const LabText('Read the formula',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                    color: labBackground,
                                    borderRadius: BorderRadius.circular(12)),
                                child: SelectableText(
                                    lesson.id == 'checkpoint'
                                        ? bilingual(context, lesson.formula,
                                            'mesmo estado inicial + mesmas atualizações → mesmo estado final\n40 épocas + 60 épocas restauradas ↔ 100 épocas contínuas')
                                        : lesson.id == 'evaluation'
                                            ? bilingual(context, lesson.formula,
                                                'Acurácia = acertos / total\nF1 = 2 × precisão × revocação / (precisão + revocação)\nMAE = (1/N) Σᵢ |yᵢ − ŷᵢ|')
                                            : lesson.formula,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: labViolet,
                                        height: 1.8))),
                            const SizedBox(height: 16),
                            LabText(copy(lesson.interpretation),
                                style: const TextStyle(
                                    color: labMuted, height: 1.7)),
                            LabNotice(copy(lesson.limit)),
                            const SizedBox(height: 8),
                            const LabText('A small, real API example',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const LabText(
                                'Import package:neural_engine/neural_engine.dart. These snippets construct models; use the linked laboratory preset for the complete training recipe.',
                                style:
                                    TextStyle(color: labMuted, fontSize: 12)),
                            const SizedBox(height: 12),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                    color: labBackground,
                                    borderRadius: BorderRadius.circular(12)),
                                child: SelectableText(lesson.code,
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        height: 1.6))),
                            const SizedBox(height: 16),
                            Wrap(spacing: 10, runSpacing: 10, children: [
                              FilledButton.icon(
                                  key: const ValueKey('learn-open-example'),
                                  onPressed: () => widget
                                      .onExample(exampleById(lesson.exampleId)),
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      size: 18),
                                  label: const LabText('Open this experiment')),
                              OutlinedButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(
                                        text:
                                            "import 'package:neural_engine/neural_engine.dart';\n\n${lesson.code}"));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: LabText(
                                                  'Example code copied.')));
                                    }
                                  },
                                  child: const LabText('Copy code')),
                              TextButton(
                                  onPressed: () => openLabLink(
                                      context, documentationUrl(source)),
                                  child:
                                      const LabText('Read the source guide ↗')),
                            ]),
                          ])),
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: 'REFERENCES',
                      title: 'Built from this project’s documentation',
                      child: Wrap(spacing: 14, runSpacing: 8, children: [
                        TextButton(
                            onPressed: () => openLabLink(
                                context,
                                documentationUrl(pt
                                    ? 'doc/models.pt-BR.md'
                                    : 'doc/models.md')),
                            child: const LabText('Model guide ↗')),
                        TextButton(
                            onPressed: () => openLabLink(
                                context,
                                documentationUrl(pt
                                    ? 'doc/evaluation.pt-BR.md'
                                    : 'doc/evaluation.md')),
                            child: const LabText('Evaluation guide ↗')),
                        TextButton(
                            onPressed: () => openLabLink(
                                context,
                                documentationUrl(pt
                                    ? 'doc/async_training.pt-BR.md'
                                    : 'doc/async_training.md')),
                            child: const LabText('Async training guide ↗')),
                        TextButton(
                            onPressed: () => openLabLink(context,
                                documentationUrl('doc/architecture.md')),
                            child: const LabText('Architecture ↗')),
                      ])),
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: 'PRACTICE',
                      title: 'Five practical exercises',
                      child: Column(children: [
                        for (final exercise in const <(String, String, String)>[
                          (
                            '1. Explore XOR capacity',
                            'Compare two and eight hidden neurons with the same learning rate.',
                            'Record both final losses and the four predicted classes.'
                          ),
                          (
                            '2. Inspect SOM topology',
                            'Compare prototypes before and after training with the U-matrix.',
                            'Identify two neighboring similar prototypes and record their RGB values.'
                          ),
                          (
                            '3. Test the CNN distribution',
                            'Classify a vertical bar and a diagonal drawing.',
                            'Record both probability vectors and explain why only the bar matches training data.'
                          ),
                          (
                            '4. Verify exact continuation',
                            'Pause, copy/load JSON, resume and compare an async run.',
                            'Reach the target epoch and obtain an exact checkpoint match on the same platform.'
                          ),
                          (
                            '5. Compare forecasting baselines',
                            'Train AirPassengers and compare its test MAE with both baselines.',
                            'Name the best method and state the test dates and one-step forecast limitation.'
                          ),
                        ])
                          ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: LabText(exercise.$1),
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: LabText('Objective: ${exercise.$2}',
                                        style:
                                            const TextStyle(color: labMuted))),
                                const SizedBox(height: 10),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: LabText(
                                        'Complete when: ${exercise.$3}',
                                        style:
                                            const TextStyle(color: labAccent))),
                                const SizedBox(height: 18),
                              ]),
                      ])),
                ])));
  }
}

import '../widgets/language_flag.dart';
import '../content/lab_examples.dart';
import '../content/lab_links.dart';
import '../widgets/lab_logo.dart';
import 'learning_page.dart';
import 'examples_page.dart';
import '../l10n/lab_copy.dart';
import 'package:material_ui/material_ui.dart';
import 'mlp_page.dart';
import 'real_world_page.dart';
import 'async_training_page.dart';
import 'model_demo_page.dart';
import 'sequence_page.dart';
import 'checkpoint_page.dart';
import '../data/demo_kind.dart';
import '../widgets/lab_design.dart';

const _experiments = <(String, String, IconData)>[
  ('MLP', 'Learn the XOR rule', Icons.hub_outlined),
  ('SOM', 'Organize color space', Icons.grid_view_rounded),
  ('CNN', 'See patterns in pixels', Icons.filter_center_focus_rounded),
  ('Autoencoder', 'Compress and reconstruct', Icons.unfold_less_rounded),
  ('Sequences', 'RNN, LSTM and GRU', Icons.waves_rounded),
  ('Checkpoints', 'Save and replay a model', Icons.save_outlined),
  ('Async training', 'Pause, resume, compare', Icons.tune_rounded),
  ('Real data', 'Evaluate beyond training', Icons.insights_rounded),
];

class ModelGallery extends StatefulWidget {
  const ModelGallery({super.key});
  @override
  State<ModelGallery> createState() => _ModelGalleryState();
}

class _ModelGalleryState extends State<ModelGallery>
    with SingleTickerProviderStateMixin {
  late final _controller =
      TabController(length: _experiments.length, vsync: this);
  final _pages = GlobalKey();
  final _englishFocus = FocusNode(debugLabel: 'English');
  final _portugueseFocus = FocusNode(debugLabel: 'Português (Brasil)');
  int _section = 0, _presetRevision = 0;
  LabExample? _example;
  void _selectModel(int index) {
    setState(() => _section = 0);
    _controller.animateTo(index);
  }

  void _openExample(LabExample example) {
    setState(() {
      _example = example;
      _presetRevision++;
      _section = 0;
    });
    _controller.animateTo(example.tab);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    _englishFocus.dispose();
    _portugueseFocus.dispose();
    super.dispose();
  }

  Widget _brand() => const Row(children: [
        LabLogo(),
        SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LabText('NEURAL ENGINE',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700)),
          LabText('The learning laboratory',
              style: TextStyle(color: labMuted, fontSize: 11)),
        ])),
      ]);

  Widget _sidebar() => Container(
      width: 246,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: const BoxDecoration(
          color: Color(0xFF0F1826),
          border: Border(right: BorderSide(color: labBorder))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _brand(),
        const SizedBox(height: 38),
        Expanded(
            child: ListView(children: [
          for (var i = 0; i < _experiments.length; i++) ...[
            if (i == 0 || i == 5)
              Padding(
                  padding: EdgeInsets.only(
                      top: i == 5 ? 26 : 0, left: 12, bottom: 12),
                  child: LabText(i == 0 ? 'EXPLORE MODELS' : 'TRAIN & EVALUATE',
                      style: const TextStyle(
                          color: labMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.7))),
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Semantics(
                    button: true,
                    selected: _controller.index == i,
                    child: Material(
                        color: _controller.index == i
                            ? const Color(0xFF213A3D)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _selectModel(i),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 13),
                                child: Row(children: [
                                  Icon(_experiments[i].$3,
                                      size: 20,
                                      color: _controller.index == i
                                          ? labAccent
                                          : labMuted),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        LabText(_experiments[i].$1,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: _controller.index == i
                                                    ? labAccent
                                                    : const Color(0xFFEAF0F9))),
                                        const SizedBox(height: 2),
                                        LabText(_experiments[i].$2,
                                            style: const TextStyle(
                                                color: labMuted, fontSize: 10)),
                                      ])),
                                ]))))))
          ],
        ])),
        const Divider(),
        const SizedBox(height: 18),
        const LabTag('Runs on your device',
            icon: Icons.shield_outlined, color: labAccent),
        const SizedBox(height: 10),
        const LabText(
            'No uploads. No account.\nJust you, the data and the model.',
            style: TextStyle(color: labMuted, fontSize: 11, height: 1.6)),
      ]));

  Widget _navButton(int index, String label) => Semantics(
      selected: _section == index,
      child: TextButton(
          key: ValueKey('section-$index'),
          onPressed: () => setState(() => _section = index),
          style: TextButton.styleFrom(
              foregroundColor: _section == index ? labAccent : labMuted,
              backgroundColor: _section == index
                  ? labAccent.withValues(alpha: .08)
                  : Colors.transparent),
          child: LabText(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))));

  Widget _languageMenu() {
    final scope = LabCopyScope.maybeOf(context);
    final language = scope?.language ?? LabLanguage.english;
    return Row(
        key: const ValueKey('language-selector'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in LabLanguage.values)
            Semantics(
                selected: language == value,
                child: IconButton(
                  key: ValueKey(value == LabLanguage.english
                      ? 'language-en'
                      : 'language-pt'),
                  focusNode: value == LabLanguage.english
                      ? _englishFocus
                      : _portugueseFocus,
                  tooltip: value == LabLanguage.english
                      ? 'English (United Kingdom)'
                      : 'Português (Brasil)',
                  onPressed: () => scope?.onChanged(value),
                  style: IconButton.styleFrom(
                      minimumSize: const Size.square(48),
                      shape: CircleBorder(
                          side: BorderSide(
                              color: language == value
                                  ? labAccent
                                  : Colors.transparent,
                              width: 2)),
                      backgroundColor: language == value
                          ? labAccent.withValues(alpha: .08)
                          : Colors.transparent),
                  icon: LanguageFlag(value),
                )),
        ]);
  }

  Widget _links() => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
            key: const ValueKey('documentation-link'),
            tooltip: tr(context, 'Documentation'),
            icon: const Icon(Icons.menu_book_outlined, size: 19),
            onPressed: () => openLabLink(
                context,
                documentationUrl(LabCopyScope.maybeOf(context)?.language ==
                        LabLanguage.portuguese
                    ? 'doc/models.pt-BR.md'
                    : 'doc/models.md'))),
        IconButton(
            key: const ValueKey('github-link'),
            tooltip: 'GitHub',
            icon: const Icon(Icons.code_rounded, size: 19),
            onPressed: () => openLabLink(context, repositoryUrl)),
      ]);

  @override
  Widget build(BuildContext context) => LabNavigation(
        select: _selectModel,
        example: _example,
        revision: _presetRevision,
        child: Scaffold(
            body: SafeArea(child: LayoutBuilder(builder: (context, bounds) {
          final wide = bounds.maxWidth >= 1100;
          return Row(children: [
            if (wide) _sidebar(),
            Expanded(
                key: const ValueKey('workspace'),
                child: Column(children: [
                  Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: tr(context, 'Main navigation'),
                      child: Material(
                          color: const Color(0xFF0F1826),
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: wide ? 28 : 16, vertical: 10),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(color: labBorder))),
                              child: Column(children: [
                                Row(children: [
                                  if (!wide)
                                    Expanded(child: _brand())
                                  else ...[
                                    _navButton(0, 'Laboratory'),
                                    const SizedBox(width: 8),
                                    _navButton(1, 'Learn'),
                                    const SizedBox(width: 8),
                                    _navButton(2, 'Examples'),
                                    const Spacer(),
                                    _links(),
                                    const SizedBox(width: 12),
                                  ],
                                  _languageMenu(),
                                ]),
                                if (!wide)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(children: [
                                        Expanded(
                                            child: Wrap(
                                                spacing: 2,
                                                runSpacing: 4,
                                                children: [
                                              _navButton(0, 'Laboratory'),
                                              _navButton(1, 'Learn'),
                                              _navButton(2, 'Examples')
                                            ])),
                                        _links(),
                                      ])),
                              ])))),
                  Expanded(
                      child: IndexedStack(index: _section, children: [
                    Column(children: [
                      if (!wide)
                        Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: DropdownButtonFormField<int>(
                              key: const ValueKey('mobile-experiment'),
                              isExpanded: true,
                              initialValue: _controller.index,
                              decoration: InputDecoration(
                                  labelText: tr(context, 'Experiment')),
                              items: [
                                for (var i = 0; i < _experiments.length; i++)
                                  DropdownMenuItem(
                                      value: i,
                                      child: LabText(
                                          '${_experiments[i].$1} · ${_experiments[i].$2}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12)))
                              ],
                              onChanged: (value) {
                                if (value != null) _selectModel(value);
                              },
                            )),
                      Expanded(
                          child: TabBarView(
                              key: _pages,
                              controller: _controller,
                              physics: const NeverScrollableScrollPhysics(),
                              children: const [
                            MlpPage(),
                            ModelDemo(kind: DemoKind.som),
                            ModelDemo(kind: DemoKind.cnn),
                            ModelDemo(kind: DemoKind.autoencoder),
                            SequencePage(),
                            CheckpointPage(),
                            AsyncTrainingPage(),
                            RealWorldPage(),
                          ])),
                    ]),
                    LearningPage(onExample: _openExample),
                    ExamplesPage(onExample: _openExample),
                  ])),
                ])),
          ]);
        }))),
      );
}

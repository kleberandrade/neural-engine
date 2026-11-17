import '../l10n/lab_copy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:neural_engine/neural_engine.dart';
import '../runners/mlp_runner.dart';
import '../data/xor_dataset.dart';
import '../painters/loss_painter.dart';
import '../painters/boundary_painter.dart';
import '../widgets/lab_design.dart';

class MlpPage extends StatefulWidget {
  const MlpPage({super.key});
  @override
  State<MlpPage> createState() => _MlpPageState();
}

class _MlpPageState extends State<MlpPage> with AutomaticKeepAliveClientMixin {
  double _units = 8, _rate = .03;
  bool _busy = false;
  NeuralNetwork? _network;
  List<double> _losses = [];
  String? _error;
  int? _trainedUnits;
  int _presetRevision = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navigation = LabNavigation.maybeOf(context);
    if (navigation == null ||
        navigation.revision == _presetRevision ||
        navigation.example?.tab != 0) {
      return;
    }
    _presetRevision = navigation.revision;
    if (_busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: LabText(
                  'Finish or cancel the active run before loading another recipe.')));
        }
      });
      return;
    }
    _units = navigation.example!.hiddenUnits!.toDouble();
    _rate = .03;
    _network = null;
    _trainedUnits = null;
    _losses = [];
    _error = null;
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final units = _units.round();
      final result = await compute(trainXor, {'units': _units, 'rate': _rate});
      if (!mounted) return;
      setState(() {
        _network =
            NeuralNetwork.fromJson(result['model']! as Map<String, dynamic>);
        _losses = result['losses']! as List<double>;
        _trainedUnits = units;
      });
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = 'Training failed. Try a fresh run with these settings.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _controls() => LabPanel(
      eyebrow: '01 / CONFIGURE',
      title: 'Build your network',
      subtitle: 'Change one setting. Train again. Observe what changes.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const LabText('Hidden layer',
            style: TextStyle(color: labMuted, fontSize: 12)),
        Row(children: [
          const Expanded(child: LabText('Neurons')),
          LabTag('${_units.round()}', color: labViolet)
        ]),
        Slider(
            value: _units,
            min: 2,
            max: 16,
            divisions: 14,
            label: tr(context, '${_units.round()}'),
            semanticFormatterCallback: (v) =>
                tr(context, '${v.round()} hidden neurons'),
            onChanged: _busy ? null : (v) => setState(() => _units = v)),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: LabText('Learning rate')),
          LabText(_rate.toStringAsFixed(3),
              style: const TextStyle(
                  color: labAccent, fontWeight: FontWeight.w600))
        ]),
        Slider(
            value: _rate,
            min: .005,
            max: .1,
            divisions: 19,
            label: _rate.toStringAsFixed(3),
            semanticFormatterCallback: (v) =>
                tr(context, 'Learning rate ${v.toStringAsFixed(3)}'),
            onChanged: _busy ? null : (v) => setState(() => _rate = v)),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 20),
        for (final pair in [
          ('Optimizer', 'Adam'),
          ('Epochs', '800'),
          ('Random seed', '42'),
          ('Loss', 'Binary cross entropy')
        ])
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LabText(pair.$1,
                    style: const TextStyle(color: labMuted, fontSize: 12)),
                const SizedBox(width: 14),
                Expanded(
                    child: LabText(pair.$2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
              ])),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _busy ? null : _run,
                icon: const Icon(Icons.play_arrow_rounded, size: 19),
                label: LabText(_busy ? 'Training…' : 'Train network'))),
        if (_busy)
          const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator()),
        if (_error != null) LabNotice(_error!, icon: Icons.error_outline),
        const LabNotice(
            'Controls apply to the next run. Charts keep the last completed result.'),
        if (LabNavigation.maybeOf(context) != null)
          TextButton.icon(
              onPressed: () => LabNavigation.maybeOf(context)!.select(6),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const LabText('Need pause and resume?')),
      ]));

  Widget _predictions() => LabPanel(
      eyebrow: '04 / VERIFY',
      title: 'Four examples. One rule.',
      subtitle: 'XOR returns 1 when its two inputs differ.',
      child: LayoutBuilder(builder: (context, bounds) {
        final width = bounds.maxWidth > 500
            ? (bounds.maxWidth - 36) / 4
            : (bounds.maxWidth - 12) / 2;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < 4; i++)
            Container(
                width: width,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: labBackground.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: labBorder)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabText(
                          '${xorInputs[i][0].toInt()}  ⊕  ${xorInputs[i][1].toInt()}',
                          style:
                              const TextStyle(color: labMuted, fontSize: 13)),
                      const SizedBox(height: 14),
                      LabText(
                          _network == null
                              ? '—'
                              : _network!
                                  .predict(xorInputs[i])
                                  .single
                                  .toStringAsFixed(4),
                          style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              color: xorTargets[i].single == 0
                                  ? const Color(0xFF80B8F7)
                                  : const Color(0xFFFFB18B))),
                      const SizedBox(height: 6),
                      LabText('Target ${xorTargets[i].single.toInt()}',
                          style:
                              const TextStyle(color: labMuted, fontSize: 11)),
                    ])),
        ]);
      }));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final model = _network ??
        NeuralNetwork(inputSize: 2, seed: 42, layers: [
          Dense(_units.round(), activation: Activation.tanh),
          Dense(1, activation: Activation.sigmoid)
        ]);
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: ListView(
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 32),
              children: [
                const LabHeader(
                    kicker: '01 / Multilayer perceptron',
                    title: 'A simple rule.\nA learned decision.',
                    description:
                        'Teach a neural network to separate XOR. Explore how a hidden layer turns four examples into a decision surface.',
                    tags: [
                      LabTag('Supervised learning', color: labAccent),
                      LabTag('4 synthetic samples'),
                      LabTag('Runs locally', icon: Icons.offline_bolt_outlined)
                    ]),
                LabColumns(
                    controls: _controls(),
                    results: Column(children: [
                      LayoutBuilder(builder: (context, bounds) {
                        final plots = [
                          LabPanel(
                              eyebrow: '02 / LEARNING',
                              title: 'Training loss',
                              subtitle:
                                  'Binary cross entropy · lower is better',
                              child: _losses.isEmpty
                                  ? const LabEmpty(
                                      title: 'Ready when you are',
                                      description:
                                          'Train the network to trace its learning curve. No training starts automatically.')
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                          LabMetric(
                                              label: tr(context, 'Final loss'),
                                              value: _losses.last
                                                  .toStringAsFixed(6),
                                              detail: '800 completed epochs'),
                                          const SizedBox(height: 18),
                                          SizedBox(
                                              height: 210,
                                              width: double.infinity,
                                              child: Semantics(
                                                  image: true,
                                                  label: tr(context,
                                                      'Training loss from ${_losses.first.toStringAsFixed(6)} to ${_losses.last.toStringAsFixed(6)} in 800 epochs'),
                                                  child: CustomPaint(
                                                      painter: LossPainter(
                                                          _losses,
                                                          epochLabel: tr(
                                                              context,
                                                              'epochs'))))),
                                          LabText(
                                              'Final binary cross entropy: ${_losses.last.toStringAsFixed(6)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: labMuted)),
                                        ])),
                          LabPanel(
                              eyebrow: '02 / DECISION SPACE',
                              title: 'What the network sees',
                              subtitle: _network == null
                                  ? 'Untrained weights · seed 42'
                                  : 'Last completed run · seed 42',
                              child: Column(children: [
                                AspectRatio(
                                    aspectRatio: 1.1,
                                    child: Semantics(
                                        image: true,
                                        label: tr(
                                            context,
                                            _network == null
                                                ? 'Untrained XOR decision surface'
                                                : 'Trained XOR decision surface; blue is class zero and orange is class one'),
                                        child: CustomPaint(
                                            painter: BoundaryPainter(model)))),
                                const SizedBox(height: 12),
                                const Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      LabTag('●  Class 0',
                                          color: Color(0xFF80B8F7)),
                                      LabTag('●  Class 1',
                                          color: Color(0xFFFFB18B))
                                    ]),
                              ])),
                        ];
                        return bounds.maxWidth >= 680
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Expanded(child: plots[0]),
                                    const SizedBox(width: 20),
                                    Expanded(child: plots[1])
                                  ])
                            : Column(children: [
                                plots[0],
                                const SizedBox(height: 20),
                                plots[1]
                              ]);
                      }),
                      const SizedBox(height: 20),
                      LabPanel(
                          eyebrow: '03 / ARCHITECTURE',
                          title: 'From inputs to a prediction',
                          trailing: LabTag(
                              _busy
                                  ? 'Training'
                                  : _network == null
                                      ? 'Not trained'
                                      : 'Trained',
                              color: _busy ? labViolet : labAccent),
                          child: _Architecture(
                              units: _trainedUnits ?? _units.round())),
                      const SizedBox(height: 20),
                      _predictions(),
                    ])),
                const LabNotice(
                    'This truth table is the whole XOR task. Training loss measures fit to these four rows; it does not establish performance on unseen real-world data.'),
              ],
            )));
  }
}

class _Architecture extends StatelessWidget {
  final int units;
  const _Architecture({required this.units});
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: labMuted, size: 18)),
            Expanded(
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (i == 1 ? labViolet : labAccent)
                            .withValues(alpha: .07),
                        border: Border.all(color: labBorder)),
                    child: Column(children: [
                      LabText('${[2, units, 1][i]}',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: i == 1 ? labViolet : labAccent)),
                      const SizedBox(height: 4),
                      LabText(['Inputs', 'Hidden', 'Output'][i],
                          style: const TextStyle(fontSize: 11, color: labMuted))
                    ]))),
          ]
        ]),
        const SizedBox(height: 14),
        const LabText('Input values → tanh activation → sigmoid probability',
            style: TextStyle(color: labMuted, fontSize: 11)),
      ]);
}

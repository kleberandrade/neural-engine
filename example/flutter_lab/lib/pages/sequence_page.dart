import '../l10n/lab_copy.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import '../runners/sequence_runner.dart';
import '../widgets/loss_chart.dart';
import '../widgets/lab_design.dart';
import '../widgets/scalar_grid.dart';

class SequencePage extends StatefulWidget {
  const SequencePage({super.key});
  @override
  State<SequencePage> createState() => _SequencePageState();
}

class _SequencePageState extends State<SequencePage>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, Object>>? _results;
  bool _busy = false;
  String? _error;
  int _selected = 0;
  @override
  bool get wantKeepAlive => true;
  Future<void> _train() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await compute(trainSequences, 180);
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = 'Training failed. Try a fresh run with these settings.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final results = _results;
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 32),
              children: [
                const LabHeader(
                    kicker: '05 / Sequence models',
                    title: 'A little history.\nThe next prediction.',
                    description:
                        'Give RNN, LSTM and GRU the same six-step sine sequence. Compare how they learn, what they predict and the states they carry.',
                    tags: [
                      LabTag('3 recurrent models', color: labViolet),
                      LabTag('24 training phases'),
                      LabTag('24 interleaved test phases')
                    ]),
                LabPanel(
                    eyebrow: '01 / COMPARE THE MODELS',
                    title: 'Same data. Different memory.',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Wrap(spacing: 8, runSpacing: 8, children: [
                            LabTag('6 time steps', color: labViolet),
                            LabTag('1 feature'),
                            LabTag('6 hidden units'),
                            LabTag('1 output', color: labAccent)
                          ]),
                          const SizedBox(height: 18),
                          const LabText(
                              'Adam 0.015 · 180 epochs · batch 8 · gradient clip 1 · seed 42',
                              style: TextStyle(color: labMuted, fontSize: 12)),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                              key: const ValueKey('train-sequence'),
                              onPressed: _busy ? null : _train,
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 18),
                              label: LabText(_busy
                                  ? 'Training…'
                                  : 'Compare sequence models')),
                          if (_busy)
                            const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: LinearProgressIndicator()),
                          if (_error != null)
                            LabNotice(_error!, icon: Icons.error_outline),
                          if (results != null)
                            const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: LabText('Sequence comparison complete',
                                    key: ValueKey('result-sequence'),
                                    style: TextStyle(color: labAccent))),
                        ])),
                const SizedBox(height: 20),
                if (results == null)
                  const LabPanel(
                      eyebrow: '02 / OBSERVE',
                      title: 'Three ways to carry context',
                      child: LabEmpty(
                          icon: Icons.waves_rounded,
                          title: 'A sequence waiting to be learned',
                          description:
                              'Train the three models to compare held-out errors, learning curves and internal states. Every input sequence begins from zero state.')),
                if (results != null) ...[
                  LabPanel(
                      eyebrow: '02 / COMPARE THE EVIDENCE',
                      title: 'Held-out errors',
                      subtitle:
                          'Parameter counts differ. Device timings are descriptive, not a controlled model ranking.',
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(columns: const [
                            DataColumn(label: LabText('Model')),
                            DataColumn(label: LabText('Parameters')),
                            DataColumn(label: LabText('Test MSE')),
                            DataColumn(label: LabText('Train ms'))
                          ], rows: [
                            for (final result in results)
                              DataRow(
                                  selected:
                                      results.indexOf(result) == _selected,
                                  onSelectChanged: (_) => setState(() =>
                                      _selected = results.indexOf(result)),
                                  cells: [
                                    DataCell(
                                        LabText(result['kind']! as String)),
                                    DataCell(
                                        LabText('${result['parameters']}')),
                                    DataCell(LabText((result['mse']! as double)
                                        .toStringAsFixed(6))),
                                    DataCell(
                                        LabText('${result['milliseconds']}')),
                                  ])
                          ]))),
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: '03 / INSPECT A MODEL',
                      title: 'Inside the sequence',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 240,
                                child: DropdownButtonFormField<int>(
                                    initialValue: _selected,
                                    decoration: InputDecoration(
                                        labelText:
                                            tr(context, 'Model to inspect')),
                                    items: [
                                      for (var i = 0; i < results.length; i++)
                                        DropdownMenuItem(
                                            value: i,
                                            child: LabText(
                                                results[i]['kind']! as String))
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selected = v!))),
                            const SizedBox(height: 24),
                            LossChart(
                                training: results[_selected]['losses']!
                                    as List<double>),
                            const SizedBox(height: 24),
                            Wrap(spacing: 40, runSpacing: 20, children: [
                              LabMetric(
                                  label: tr(context, 'Next target'),
                                  value: (results[_selected]['targets']!
                                          as List<double>)
                                      .first
                                      .toStringAsFixed(4),
                                  color: labViolet),
                              LabMetric(
                                  label: tr(context, 'Predicted next value'),
                                  value: (results[_selected]['predictions']!
                                          as List<double>)
                                      .first
                                      .toStringAsFixed(4)),
                              LabMetric(
                                  label: tr(context, 'Test MAE'),
                                  value: (results[_selected]['mae']! as double)
                                      .toStringAsFixed(4)),
                            ]),
                            const SizedBox(height: 18),
                            LabText(
                                'Input: ${(results[_selected]['input']! as List<double>).map((v) => v.toStringAsFixed(3)).join(', ')}',
                                style: const TextStyle(
                                    color: labMuted, fontSize: 12)),
                            const SizedBox(height: 24),
                            Wrap(spacing: 32, runSpacing: 24, children: [
                              ScalarGrid(
                                  title: 'Hidden state · timestep × unit',
                                  values: results[_selected]['hidden']!
                                      as List<double>,
                                  columns: 6),
                              if (_selected == 1)
                                ScalarGrid(
                                    title: 'LSTM memory state',
                                    values: results[_selected]['memory']!
                                        as List<double>,
                                    columns: 6),
                            ]),
                          ])),
                  const LabNotice(
                      'Test phases interleave the same sine family. These results do not establish long-memory capability or performance on real time series.'),
                ],
              ],
            )));
  }
}

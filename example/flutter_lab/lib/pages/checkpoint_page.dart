import '../l10n/lab_copy.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../runners/checkpoint_runner.dart';
import '../widgets/lab_design.dart';

class CheckpointPage extends StatefulWidget {
  const CheckpointPage({super.key});
  @override
  State<CheckpointPage> createState() => _CheckpointPageState();
}

class _CheckpointPageState extends State<CheckpointPage>
    with AutomaticKeepAliveClientMixin {
  final _json = TextEditingController();
  String _family = 'MLP';
  Map<String, Object>? _result;
  String? _error;
  bool _busy = false;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _json.dispose();
    super.dispose();
  }

  Future<void> _run(String action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await compute(runCheckpointDemo, <String, Object>{
        'family': _family,
        'action': action,
        'json': _json.text
      });
      if (mounted) {
        setState(() {
          _result = result;
          _json.text = result['json']! as String;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            'Could not restore this checkpoint. Select the matching model and use JSON exported by this walkthrough.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _json.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: LabText(
              'JSON copied. Save it as a text file to keep it after closing the app.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final result = _result;
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              key: const ValueKey('checkpoint-scroll'),
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 32),
              children: [
                const LabHeader(
                    kicker: 'Checkpoints / Reproducibility',
                    title: 'Close the tab.\nKeep the learning.',
                    description:
                        'Save a model after 40 epochs, restore it and train 60 more. Then compare the full state with an uninterrupted 100-epoch run.',
                    tags: [
                      LabTag('40 + 60 = 100', color: labAccent),
                      LabTag('Model + Adam state', color: labViolet),
                      LabTag('Exact replay')
                    ]),
                LabPanel(
                    eyebrow: '01 / THE WALKTHROUGH',
                    title: 'One model. Two training sessions.',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 240,
                              child: DropdownButtonFormField<String>(
                                  initialValue: _family,
                                  decoration: InputDecoration(
                                      labelText: tr(context, 'Model family')),
                                  items: [
                                    for (final family in [
                                      'MLP',
                                      'CNN',
                                      'RNN',
                                      'LSTM',
                                      'GRU'
                                    ])
                                      DropdownMenuItem(
                                          value: family, child: LabText(family))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (v) => setState(() {
                                            _family = v!;
                                            _result = null;
                                            _error = null;
                                            _json.clear();
                                          }))),
                          const SizedBox(height: 20),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            FilledButton.icon(
                                key: const ValueKey('checkpoint-start'),
                                onPressed: _busy ? null : () => _run('start'),
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label: const LabText('Train 40 epochs')),
                            OutlinedButton(
                                key: const ValueKey('checkpoint-resume'),
                                onPressed: _busy ? null : () => _run('resume'),
                                child: const LabText('Resume +60 epochs')),
                          ]),
                          if (_busy)
                            const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: LinearProgressIndicator()),
                          if (result != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: LabText(
                                    'Completed epochs: ${result['epochs']}',
                                    key: const ValueKey('checkpoint-result'),
                                    style: const TextStyle(
                                        color: labAccent,
                                        fontWeight: FontWeight.w600))),
                          const LabNotice(
                              'Train first, copy the JSON below and save it as a text file. To restore, select the same model, paste the JSON and press Load JSON.'),
                        ])),
                if (result != null) ...[
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: '02 / VERIFY THE REPLAY',
                      title: 'Did the model remember everything?',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(spacing: 42, runSpacing: 20, children: [
                              LabMetric(
                                  label: tr(context, 'Mean training loss'),
                                  value: (result['loss']! as double)
                                      .toStringAsFixed(6)),
                              LabMetric(
                                  label: tr(context, 'Checkpoint size'),
                                  value: '${result['bytes']}',
                                  detail: 'UTF-8 bytes',
                                  color: labViolet),
                              LabMetric(
                                  label: tr(context, 'State matches reference'),
                                  value: '${result['exact']}',
                                  detail: 'Model + Adam state'),
                            ]),
                            const SizedBox(height: 22),
                            LabText(
                                'Full model + Adam state matches uninterrupted run: ${result['exact']}',
                                style: const TextStyle(color: labAccent)),
                            const SizedBox(height: 6),
                            LabText(
                                'Maximum prediction difference: ${result['maxDifference']}',
                                style: const TextStyle(
                                    color: labMuted, fontSize: 12)),
                            const SizedBox(height: 18),
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(columns: const [
                                  DataColumn(label: LabText('Target')),
                                  DataColumn(
                                      label: LabText('Restored prediction')),
                                  DataColumn(
                                      label:
                                          LabText('Uninterrupted prediction'))
                                ], rows: [
                                  for (var i = 0;
                                      i < (result['targets']! as List).length;
                                      i++)
                                    DataRow(cells: [
                                      for (final field in [
                                        'targets',
                                        'predictions',
                                        'reference'
                                      ])
                                        DataCell(LabText(((result[field]!
                                                as List)[i] as List<double>)
                                            .map((v) => v.toStringAsFixed(4))
                                            .join(', ')))
                                    ])
                                ])),
                          ])),
                ],
                const SizedBox(height: 20),
                LabPanel(
                    eyebrow: '03 / SAVE & RESTORE',
                    title: 'Your portable checkpoint',
                    subtitle:
                        'The JSON is the source of truth. Nothing is saved automatically when you close the tab.',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                              key: const ValueKey('checkpoint-json'),
                              controller: _json,
                              enabled: !_busy,
                              minLines: 5,
                              maxLines: 8,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12),
                              decoration: InputDecoration(
                                  labelText: tr(context, 'Checkpoint JSON'),
                                  alignLabelWithHint: true)),
                          const SizedBox(height: 14),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            OutlinedButton.icon(
                                onPressed:
                                    _busy || _json.text.isEmpty ? null : _copy,
                                icon: const Icon(Icons.copy_outlined, size: 16),
                                label: const LabText('Copy JSON to save')),
                            OutlinedButton(
                                key: const ValueKey('checkpoint-load'),
                                onPressed: _busy ? null : () => _run('load'),
                                child: const LabText('Load JSON')),
                          ]),
                          if (_error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: LabText(_error!,
                                    key: const ValueKey('checkpoint-error'),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error))),
                        ])),
                const LabNotice(
                    'Exact continuation requires the same data, order, loss, batch size, clipping, SDK and platform. This walkthrough fixes those settings. Its JSON format differs from Async training. SOM uses a separate schedule. Browser compute can briefly block.'),
              ],
            )));
  }
}

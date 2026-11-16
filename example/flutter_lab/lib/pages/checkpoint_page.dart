import 'package:flutter/foundation.dart';
// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../runners/checkpoint_runner.dart';

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
      if (mounted) setState(() => _error = 'Checkpoint rejected: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _json.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'JSON copied. Save it as a text file to keep it after closing the app.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final result = _result;
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Save → load → resume',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Text(
                  'Train 40 epochs, copy the checkpoint JSON and save it as a text file. '
                  'You can close the app, reopen it, choose the same model and paste the JSON below. '
                  'Load recreates the model and Adam state; resume adds 60 epochs. '
                  'Compare with a fresh uninterrupted run on the same synthetic data.'),
              DropdownButton<String>(
                  value: _family,
                  items: [
                    for (final family in ['MLP', 'CNN', 'RNN', 'LSTM', 'GRU'])
                      DropdownMenuItem(value: family, child: Text(family))
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                            _family = value!;
                            _result = null;
                            _error = null;
                            _json.clear();
                          })),
              Wrap(spacing: 12, runSpacing: 8, children: [
                FilledButton(
                    key: const ValueKey('checkpoint-start'),
                    onPressed: _busy ? null : () => _run('start'),
                    child: const Text('Train 40 epochs')),
                OutlinedButton(
                    key: const ValueKey('checkpoint-load'),
                    onPressed: _busy ? null : () => _run('load'),
                    child: const Text('Load JSON')),
                OutlinedButton(
                    key: const ValueKey('checkpoint-resume'),
                    onPressed: _busy ? null : () => _run('resume'),
                    child: const Text('Resume +60 epochs')),
                OutlinedButton(
                    onPressed: _busy || _json.text.isEmpty ? null : _copy,
                    child: const Text('Copy JSON to save'))
              ]),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Text(_error!, key: const ValueKey('checkpoint-error')),
              const SizedBox(height: 12),
              if (result != null) ...[
                Text('Completed epochs: ${result['epochs']}',
                    key: const ValueKey('checkpoint-result')),
                Text(
                    'Mean training loss: ${(result['loss']! as double).toStringAsFixed(6)}'),
                Text('Checkpoint UTF-8: ${result['bytes']} bytes'),
                Text(
                    'Full model + Adam state matches uninterrupted run: ${result['exact']}'),
                Text(
                    'Maximum prediction difference: ${result['maxDifference']}'),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(columns: const [
                      DataColumn(label: Text('Target')),
                      DataColumn(label: Text('Restored prediction')),
                      DataColumn(label: Text('Uninterrupted prediction'))
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
                            DataCell(Text(
                                ((result[field]! as List)[i] as List<double>)
                                    .map((v) => v.toStringAsFixed(4))
                                    .join(', ')))
                        ])
                    ])),
              ],
              const SizedBox(height: 12),
              TextField(
                  key: const ValueKey('checkpoint-json'),
                  controller: _json,
                  enabled: !_busy,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                      labelText: 'Checkpoint JSON',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true)),
              const SizedBox(height: 12),
              const Text(
                  'Exact continuation requires the same data/order, loss, batch size, '
                  'clipping, SDK and platform. This demo fixes those settings. '
                  'SOM uses its own fit/decay schedule and is not a TrainingSession model. '
                  'Clipboard export is explicit; the app does not automatically write a file. '
                  'On Flutter web, compute runs on the browser event loop.'),
            ])));
  }
}

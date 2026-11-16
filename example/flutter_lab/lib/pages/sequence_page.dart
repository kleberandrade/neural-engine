import 'package:flutter/foundation.dart';
// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import '../runners/sequence_runner.dart';
import '../painters/curve_painter.dart';
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
      if (mounted) setState(() => _error = '$error');
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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Text('RNN → LSTM → GRU',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Text(
                  'Six sine samples → predict the next sample. All three models use 6 hidden units and the same data; parameter counts differ. Each sequence starts from zero state.'),
              const SizedBox(height: 16),
              Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                      key: const ValueKey('train-sequence'),
                      onPressed: _busy ? null : _train,
                      child: Text(
                          _busy ? 'Training…' : 'Compare sequence models'))),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
              if (results != null) ...[
                const Text('Sequence comparison complete',
                    key: ValueKey('result-sequence')),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(columns: const [
                      DataColumn(label: Text('Model')),
                      DataColumn(label: Text('Parameters')),
                      DataColumn(label: Text('Test MSE')),
                      DataColumn(label: Text('Train ms'))
                    ], rows: [
                      for (final result in results)
                        DataRow(cells: [
                          DataCell(Text(result['kind']! as String)),
                          DataCell(Text('${result['parameters']}')),
                          DataCell(Text(
                              (result['mse']! as double).toStringAsFixed(6))),
                          DataCell(Text('${result['milliseconds']}'))
                        ])
                    ])),
                DropdownButton<int>(
                    value: _selected,
                    items: [
                      for (var i = 0; i < results.length; i++)
                        DropdownMenuItem(
                            value: i,
                            child: Text(results[i]['kind']! as String))
                    ],
                    onChanged: (v) => setState(() => _selected = v!)),
                const Text('Training MSE by epoch'),
                SizedBox(
                    height: 150,
                    child: CustomPaint(
                        painter: CurvePainter(
                            results[_selected]['losses']! as List<double>))),
                const SizedBox(height: 16),
                Text(
                    'First held-out input: ${(results[_selected]['input']! as List<double>).map((v) => v.toStringAsFixed(3)).join(', ')}'),
                Text(
                    'Next target: ${(results[_selected]['targets']! as List<double>).first.toStringAsFixed(4)} · predicted: ${(results[_selected]['predictions']! as List<double>).first.toStringAsFixed(4)}'),
                const SizedBox(height: 12),
                Wrap(spacing: 24, runSpacing: 16, children: [
                  ScalarGrid(
                      title: 'Hidden state: rows=timestep, columns=unit',
                      values: results[_selected]['hidden']! as List<double>,
                      columns: 6),
                  if (_selected == 1)
                    ScalarGrid(
                        title: 'LSTM memory state',
                        values: results[_selected]['memory']! as List<double>,
                        columns: 6),
                ]),
                const Text(
                    'Test phases interleave the same synthetic sine family. These results do not establish long-memory capability or performance on real time series. Training time includes this device/runtime and is not a controlled model ranking.'),
              ],
            ])));
  }
}

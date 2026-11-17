import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:neural_engine/neural_engine.dart';

import '../runners/real_world_runner.dart';
import '../widgets/loss_chart.dart';

class RealWorldPage extends StatefulWidget {
  const RealWorldPage({super.key});
  @override
  State<RealWorldPage> createState() => _RealWorldPageState();
}

class _RealWorldPageState extends State<RealWorldPage>
    with AutomaticKeepAliveClientMixin {
  String _name = 'Iris', _status = 'Ready';
  AsyncTrainingTask? _task;
  StreamSubscription<TrainingProgress>? _subscription;
  TrainingProgress? _progress;
  Map<String, Object?>? _report;
  String? _error;
  final _losses = <double>[], _validationLosses = <double>[];
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _task?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _train() async {
    final experiment = realWorldExperiment(_name);
    final job = AsyncTrainingTask.start(experiment.request());
    setState(() {
      _task = job;
      _report = null;
      _progress = null;
      _error = null;
      _status = 'Training';
      _losses.clear();
      _validationLosses.clear();
    });
    _subscription = job.progress.listen((p) {
      if (mounted) {
        setState(() {
          _progress = p;
          _losses.add(p.loss);
          if (p.validationLoss != null) {
            _validationLosses.add(p.validationLoss!);
          }
        });
      }
    });
    try {
      final result = await job.result;
      if (!mounted) return;
      setState(() {
        _status = result.cancelled
            ? 'Cancelled; test partition was not evaluated'
            : 'Complete';
        if (!result.cancelled) _report = experiment.report(result);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _status = 'Failed; start again to retry';
        });
      }
    } finally {
      await _subscription?.cancel();
      if (mounted) {
        setState(() => _task = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final report = _report;
    final rows = report?['sampleRows'] as List<Map<String, Object>>?;
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
                key: const ValueKey('real-world-scroll'),
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Real data · honest evaluation',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Text(
                      'Pinned offline datasets with source attribution. Fixed recipes; test data is reserved for the final report. '
                      'Results from a small classic dataset are educational, not a production-quality claim.'),
                  DropdownButton<String>(
                      key: const ValueKey('real-world-dataset'),
                      value: _name,
                      items: [
                        for (final name in ['Iris', 'AirPassengers'])
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: _task != null
                          ? null
                          : (v) => setState(() {
                                _name = v!;
                                _report = null;
                                _progress = null;
                                _error = null;
                                _losses.clear();
                                _validationLosses.clear();
                                _status = 'Ready';
                              })),
                  Text(_name == 'Iris'
                      ? 'MLP 4 → 8 tanh → 3 softmax. Deduplicate, stratify by class, fit scaler on training only. '
                          'Compare held-out accuracy/F1 with a training-majority classifier.'
                      : 'GRU with 12 monthly lags. Train through 1956, validate in 1957–1958, test in 1959–1960. '
                          'One-step forecasts use observations available before each target, not a recursive 24-month forecast. '
                          'Compare MAE in thousands against previous-month and previous-year baselines.'),
                  Text(_name == 'Iris'
                      ? 'Adam 0.01 · batch 16 · 120 epochs · categorical cross entropy · seed 42'
                      : 'GRU hidden size 8 · Adam 0.01 · batch 12 · 100 epochs · mean squared error · chronological order · seed 42'),
                  Wrap(spacing: 12, children: [
                    FilledButton(
                        key: const ValueKey('real-world-train'),
                        onPressed: _task != null ? null : _train,
                        child: const Text('Train on real data')),
                    OutlinedButton(
                        key: const ValueKey('real-world-cancel'),
                        onPressed: _task == null ? null : () => _task?.cancel(),
                        child: const Text('Cancel')),
                  ]),
                  Text(_status, key: const ValueKey('real-world-status')),
                  if (_task != null)
                    LinearProgressIndicator(value: _progress?.fraction ?? 0),
                  if (_progress != null)
                    Text(
                        'Epoch ${_progress!.epochsCompleted} · loss ${_progress!.loss.toStringAsFixed(5)} · validation ${_progress!.validationLoss?.toStringAsFixed(5)}'),
                  if (_error != null) Text(_error!),
                  if (_losses.isNotEmpty)
                    LossChart(
                        training: List.of(_losses),
                        validation: List.of(_validationLosses)),
                  if (report != null) ...[
                    Text('${report['dataset']} results',
                        key: const ValueKey('real-world-result')),
                    for (final entry in report.entries.where(
                        (e) => !['sampleRows', 'scaler'].contains(e.key)))
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text('${entry.key}: ${entry.value}')),
                    const SizedBox(height: 12),
                    const Text('Reserved test predictions'),
                    if (rows != null)
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(columns: [
                            for (final key in rows.first.keys)
                              DataColumn(label: Text(key)),
                          ], rows: [
                            for (final row in rows)
                              DataRow(cells: [
                                for (final value in row.values)
                                  DataCell(Text(value is double
                                      ? value.toStringAsFixed(2)
                                      : '$value')),
                              ]),
                          ])),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                      'Sources and snapshots: example/data/README.md. Tutorial: doc/real_world.pt-BR.md. '
                      'Validation and test statistics never enter the scaler fit. Baselines are reported even if they outperform the neural network.'),
                ])));
  }
}

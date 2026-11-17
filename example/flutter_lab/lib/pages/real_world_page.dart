import '../l10n/lab_copy.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:neural_engine/neural_engine.dart';

import '../runners/real_world_runner.dart';
import '../widgets/loss_chart.dart';
import '../widgets/lab_design.dart';

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
  int _presetRevision = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navigation = LabNavigation.maybeOf(context);
    if (navigation == null ||
        navigation.revision == _presetRevision ||
        navigation.example?.tab != 7) {
      return;
    }
    _presetRevision = navigation.revision;
    if (_task != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: LabText(
                  'Finish or cancel the active run before loading another recipe.')));
        }
      });
      return;
    }
    _name = navigation.example!.dataset!;
    _report = null;
    _progress = null;
    _error = null;
    _losses.clear();
    _validationLosses.clear();
    _status = 'Ready';
  }

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
          _error = 'Training failed. Try a fresh run with these settings.';
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
    final iris = _name == 'Iris';
    String number(String key) => (report![key]! as num).toStringAsFixed(3);
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              key: const ValueKey('real-world-scroll'),
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 32),
              children: [
                const LabHeader(
                    kicker: 'Real data / Evaluation',
                    title: 'Good fit is a start.\nEvidence goes further.',
                    description:
                        'Train on one partition, validate on another and reserve the test set for the final report. Then compare the network with a simple baseline.',
                    tags: [
                      LabTag('Offline datasets', color: labAccent),
                      LabTag('Reserved test partition', color: labViolet),
                      LabTag('No uploads')
                    ]),
                LabPanel(
                    eyebrow: '01 / EXPERIMENT',
                    title: 'Choose your question',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 300,
                              child: DropdownButtonFormField<String>(
                                  key: const ValueKey('real-world-dataset'),
                                  initialValue: _name,
                                  decoration: InputDecoration(
                                      labelText: tr(context, 'Dataset')),
                                  items: [
                                    for (final name in [
                                      'Iris',
                                      'AirPassengers'
                                    ])
                                      DropdownMenuItem(
                                          value: name, child: LabText(name))
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
                                          }))),
                          const SizedBox(height: 20),
                          LabText(
                              iris
                                  ? 'Classify a flower from four measurements.'
                                  : 'Predict the next month of airline demand.',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          LabText(
                              iris
                                  ? 'MLP 4 → 8 tanh → 3 softmax. Exact duplicates are removed before a seeded, stratified split. The scaler is fitted on training data only.'
                                  : 'GRU with 12 monthly lags and 8 hidden units. Train through 1956, validate in 1957–1958 and test in 1959–1960. One-step predictions use observations available before each target.',
                              style: const TextStyle(
                                  color: labMuted, height: 1.6)),
                          const SizedBox(height: 18),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            const LabTag('Adam 0.01'),
                            LabTag(iris ? '120 epochs' : '100 epochs'),
                            LabTag(iris ? 'Batch 16' : 'Batch 12'),
                            LabTag(
                                iris ? 'Cross entropy' : 'Mean squared error'),
                            const LabTag('Seed 42'),
                          ]),
                          const SizedBox(height: 22),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            FilledButton.icon(
                                key: const ValueKey('real-world-train'),
                                onPressed: _task != null ? null : _train,
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label: const LabText('Train on real data')),
                            OutlinedButton(
                                key: const ValueKey('real-world-cancel'),
                                onPressed: _task == null
                                    ? null
                                    : () => _task?.cancel(),
                                child: const LabText('Cancel')),
                          ]),
                          const SizedBox(height: 16),
                          Semantics(
                              liveRegion: true,
                              child: LabText(_status,
                                  key: const ValueKey('real-world-status'),
                                  style: const TextStyle(
                                      color: labAccent,
                                      fontWeight: FontWeight.w600))),
                          if (report != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: LabText('${report['dataset']} results',
                                    key: const ValueKey('real-world-result'),
                                    style: const TextStyle(
                                        color: labMuted, fontSize: 12))),
                          if (_task != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: LinearProgressIndicator(
                                    value: _progress?.fraction ?? 0)),
                          if (_progress != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: LabText(
                                    'Epoch ${_progress!.epochsCompleted} · loss ${_progress!.loss.toStringAsFixed(5)} · validation ${_progress!.validationLoss?.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                        color: labMuted, fontSize: 12))),
                          if (_error != null)
                            LabNotice(_error!, icon: Icons.error_outline),
                        ])),
                const SizedBox(height: 20),
                LabPanel(
                    eyebrow: '02 / LEARNING',
                    title: 'Training and validation, side by side',
                    child: _losses.isEmpty
                        ? const LabEmpty(
                            title: 'An honest comparison starts here',
                            description:
                                'Start a run to see both loss curves on the same scale. Test data stays reserved until training is complete.')
                        : LossChart(
                            training: List.of(_losses),
                            validation: List.of(_validationLosses))),
                if (report != null) ...[
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: '03 / RESERVED TEST SET',
                      title: 'How well did it generalize?',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                                spacing: 42,
                                runSpacing: 24,
                                children: iris
                                    ? [
                                        LabMetric(
                                            label: tr(context, 'Test accuracy'),
                                            value:
                                                '${((report['testAccuracy']! as num) * 100).toStringAsFixed(1)}%'),
                                        LabMetric(
                                            label: tr(context, 'Macro F1'),
                                            value: number('testMacroF1'),
                                            color: labViolet),
                                        LabMetric(
                                            label: tr(
                                                context, 'Majority baseline'),
                                            value:
                                                '${((report['baselineAccuracy']! as num) * 100).toStringAsFixed(1)}%',
                                            color: labMuted),
                                      ]
                                    : [
                                        LabMetric(
                                            label: tr(context, 'Test MAE'),
                                            value: number('testMAEThousands'),
                                            detail: 'Thousands of passengers'),
                                        LabMetric(
                                            label: tr(context, 'Test RMSE'),
                                            value: number('testRMSEThousands'),
                                            color: labViolet),
                                        LabMetric(
                                            label: tr(
                                                context, 'Previous year MAE'),
                                            value:
                                                number('seasonalMAEThousands'),
                                            color: labMuted),
                                        LabMetric(
                                            label: tr(
                                                context, 'Previous month MAE'),
                                            value: number(
                                                'persistenceMAEThousands'),
                                            color: labMuted),
                                      ]),
                            const SizedBox(height: 20),
                            const Divider(),
                            LabNotice(iris
                                ? 'A small classic dataset is an educational benchmark, not a production-quality claim.'
                                : 'The baseline can win. These are one-step predictions, not a recursive 24-month forecast.'),
                            ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const LabText(
                                    'Split, protocol and complete metrics',
                                    style: TextStyle(fontSize: 13)),
                                children: [
                                  for (final entry in report.entries.where(
                                      (e) => !['sampleRows', 'scaler']
                                          .contains(e.key)))
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: LabText(
                                                '${entry.key}: ${entry.value}',
                                                style: const TextStyle(
                                                    color: labMuted,
                                                    fontSize: 12)))),
                                ]),
                          ])),
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: '04 / INSPECT THE EXAMPLES',
                      title: 'Reserved test predictions',
                      child: rows == null
                          ? const SizedBox.shrink()
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(columns: [
                                for (final key in rows.first.keys)
                                  DataColumn(label: LabText(key))
                              ], rows: [
                                for (final row in rows)
                                  DataRow(cells: [
                                    for (final value in row.values)
                                      DataCell(LabText(value is num
                                          ? value == value.roundToDouble()
                                              ? value.toInt().toString()
                                              : value.toStringAsFixed(2)
                                          : '$value'))
                                  ])
                              ]))),
                ],
                const LabNotice(
                    'Dataset snapshots and attribution are included with the project. Validation and test statistics never enter the scaler fit. Cancelling skips test evaluation; starting again trains a fresh model.'),
              ],
            )));
  }
}

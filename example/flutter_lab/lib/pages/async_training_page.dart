import '../l10n/lab_copy.dart';
import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:neural_engine/neural_engine.dart';

import '../runners/async_demo_recipe.dart';
import '../widgets/loss_chart.dart';
import '../widgets/lab_design.dart';

class AsyncTrainingPage extends StatefulWidget {
  final TrainingExecution execution;
  const AsyncTrainingPage({
    super.key,
    this.execution = TrainingExecution.automatic,
  });
  @override
  State<AsyncTrainingPage> createState() => _AsyncTrainingPageState();
}

class _AsyncTrainingPageState extends State<AsyncTrainingPage>
    with AutomaticKeepAliveClientMixin {
  String _family = 'MLP';
  int _goal = 100, _interactions = 0;
  int _frequency = 1, _chunk = 32;
  bool _budget = false;
  EvaluationProgress? _evaluation;
  StreamSubscription<EvaluationProgress>? _evaluationSubscription;
  AsyncTrainingTask? _task;
  StreamSubscription<TrainingProgress>? _subscription;
  TrainingCheckpoint? _checkpoint;
  TrainingProgress? _progress;
  final _json = TextEditingController();
  final _losses = <double>[];
  String _status = 'Ready';
  String? _error, _comparison, _importError;
  Duration _elapsed = Duration.zero;
  bool _cancelling = false;
  bool _pausing = false;
  final _validationLosses = <double>[];
  final _recipes = <String, AsyncDemoRecipe>{};
  bool get _busy => _task != null;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _task?.cancel();
    _subscription?.cancel();
    _evaluationSubscription?.cancel();
    _json.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _checkpoint = null;
      _progress = null;
      _evaluation = null;
      _comparison = null;
      _error = null;
      _importError = null;
      _losses.clear();
      _validationLosses.clear();
      _json.clear();
      _elapsed = Duration.zero;
      _status = 'Ready';
    });
  }

  void _stop({required bool pause}) {
    _task!.cancel();
    setState(() {
      _cancelling = true;
      _pausing = pause;
      _status = pause
          ? 'Pausing after current epoch'
          : 'Cancelling after current epoch';
    });
  }

  void _saveJson() {
    _json.text = jsonEncode({
      'format': 'neural-engine-async-lab',
      'version': 1,
      'family': _family,
      'goal': _goal,
      'checkpoint': _checkpoint!.toJson(),
    });
  }

  void _load() {
    FocusScope.of(context).unfocus();
    try {
      final data = jsonDecode(_json.text) as Map<String, dynamic>;
      if (data['format'] != 'neural-engine-async-lab' || data['version'] != 1) {
        throw const FormatException('Expected an async lab checkpoint.');
      }
      final family = data['family'] as String;
      final recipe = AsyncDemoRecipe(family);
      final checkpoint = TrainingCheckpoint.fromJson(
          data['checkpoint'] as Map<String, dynamic>);
      recipe.validateCheckpoint(checkpoint);
      recipe.predictions(checkpoint);
      final goal = data['goal'] as int;
      if (goal < 10 || goal > 1000 || checkpoint.epochsCompleted > goal) {
        throw const FormatException('Invalid target epoch count.');
      }
      setState(() {
        _family = family;
        _goal = goal;
        _checkpoint = checkpoint;
        _elapsed = Duration.zero;
        _losses.clear();
        _validationLosses.clear();
        _progress = null;
        _comparison = null;
        _error = null;
        _importError = null;
        _status = 'Loaded at epoch ${checkpoint.epochsCompleted}';
      });
    } catch (error) {
      setState(() => _importError =
          'Checkpoint rejected. Use JSON exported by this lab with the matching model, optimizer and seed.');
    }
  }

  Future<void> _run({bool resume = false, bool compare = false}) async {
    FocusScope.of(context).unfocus();
    final recipe =
        _recipes.putIfAbsent(_family, () => AsyncDemoRecipe(_family));
    final previous = _checkpoint;
    final from = resume ? previous! : recipe.initial;
    final epochs =
        compare ? previous!.epochsCompleted : _goal - from.epochsCompleted;
    if (epochs <= 0) return;
    final job = AsyncTrainingTask.start(
        recipe.request(from, epochs,
            batchesPerYield: _frequency,
            evaluationSamplesPerYield: _chunk,
            maxWorkDuration: _budget ? const Duration(milliseconds: 8) : null),
        execution: widget.execution);
    setState(() {
      _task = job;
      _error = null;
      _importError = null;
      _progress = null;
      _evaluation = null;
      _cancelling = false;
      _pausing = false;
      _status = compare ? 'Comparing uninterrupted run' : 'Training';
      if (!compare) {
        _losses.clear();
        _validationLosses.clear();
        _comparison = null;
      }
    });
    _evaluationSubscription = job.evaluationProgress.listen((p) {
      if (mounted) setState(() => _evaluation = p);
    });
    _subscription = job.progress.listen((p) {
      if (mounted) {
        setState(() {
          _progress = p;
          if (!compare) {
            _losses.add(p.loss);
            if (p.validationLoss != null) {
              _validationLosses.add(p.validationLoss!);
            }
          }
        });
      }
    });
    try {
      final result = await job.result;
      if (!mounted) return;
      setState(() {
        _elapsed = result.elapsed;
        if (compare) {
          _comparison = result.cancelled
              ? 'Comparison cancelled'
              : 'Exact checkpoint match: ${jsonEncode(previous!.toJson()) == jsonEncode(result.checkpoint.toJson())}';
        } else {
          _checkpoint = result.checkpoint;
          _saveJson();
        }
        _status = result.cancelled
            ? '${_pausing ? 'Paused' : 'Cancelled'} at epoch ${result.checkpoint.epochsCompleted}'
            : compare
                ? 'Comparison complete'
                : 'Completed at epoch ${result.checkpoint.epochsCompleted}';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              'Training failed. The previous saved checkpoint is still available.';
          _status = 'Failed; previous saved checkpoint retained';
        });
      }
    } finally {
      await _subscription?.cancel();
      await _evaluationSubscription?.cancel();
      if (mounted) {
        setState(() {
          _task = null;
          _cancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final completed = _checkpoint?.epochsCompleted ?? 0;
    final p = _progress;
    final recipe =
        _recipes.putIfAbsent(_family, () => AsyncDemoRecipe(_family));
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              key: const ValueKey('async-scroll'),
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 32),
              children: [
                const LabHeader(
                    kicker: 'Training workspace',
                    title: 'Keep learning.\nStay in control.',
                    description:
                        'Train a little at a time. Pause safely, inspect what changed and continue from exactly where you left off.',
                    tags: [
                      LabTag('6 model recipes', color: labViolet),
                      LabTag('Live validation', color: labAccent),
                      LabTag('Resumable checkpoints')
                    ]),
                LabPanel(
                    eyebrow: '01 / EXPERIMENT',
                    title: 'Set up your run',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                              spacing: 24,
                              runSpacing: 16,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                    width: 230,
                                    child: DropdownButtonFormField<String>(
                                        key: const ValueKey('async-family'),
                                        initialValue: _family,
                                        decoration: InputDecoration(
                                            labelText:
                                                tr(context, 'Model family')),
                                        items: [
                                          for (final name in [
                                            'MLP',
                                            'CNN',
                                            'RNN',
                                            'LSTM',
                                            'GRU',
                                            'Autoencoder'
                                          ])
                                            DropdownMenuItem(
                                                value: name,
                                                child: LabText(name))
                                        ],
                                        onChanged: _busy
                                            ? null
                                            : (v) {
                                                setState(() => _family = v!);
                                                _reset();
                                              })),
                                LabMetric(
                                    label: tr(context, 'Target total epochs'),
                                    value: '$_goal'),
                                LabMetric(
                                    label: tr(context, 'Training samples'),
                                    value: '${recipe.inputs.length}',
                                    color: labViolet),
                                LabMetric(
                                    label: tr(context, 'Validation samples'),
                                    value: '${recipe.validationInputs.length}',
                                    color: labViolet),
                              ]),
                          const SizedBox(height: 16),
                          Slider(
                              key: const ValueKey('async-epochs'),
                              value: _goal.toDouble(),
                              min: 10,
                              max: 1000,
                              divisions: 99,
                              semanticFormatterCallback: (v) =>
                                  tr(context, '${v.round()} target epochs'),
                              onChanged: _busy || _checkpoint != null
                                  ? null
                                  : (v) => setState(() => _goal = v.round())),
                          const SizedBox(height: 10),
                          LabText(recipe.architecture,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          LabText(
                              'Adam · learning rate 0.02 · batch ${recipe.batchSize} · seed 42 · gradient clip 1',
                              style: const TextStyle(
                                  color: labMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          LabText('Loss: ${recipe.loss.name}',
                              style: const TextStyle(
                                  color: labMuted, fontSize: 12)),
                          LabNotice(recipe.dataDescription),
                          ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const LabText('Browser scheduling',
                                  style: TextStyle(fontSize: 13)),
                              subtitle: const LabText(
                                  'Advanced · trade throughput for more UI pauses',
                                  style:
                                      TextStyle(fontSize: 11, color: labMuted)),
                              children: [
                                Wrap(
                                    spacing: 24,
                                    runSpacing: 12,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const LabText('Batches per UI yield'),
                                      DropdownButton<int>(
                                          key:
                                              const ValueKey('async-frequency'),
                                          value: _frequency,
                                          items: [
                                            for (final v in [1, 4, 16])
                                              DropdownMenuItem(
                                                  value: v,
                                                  child: LabText(v == 1
                                                      ? '1 batch'
                                                      : '$v batches'))
                                          ],
                                          onChanged: _busy
                                              ? null
                                              : (v) => setState(
                                                  () => _frequency = v!)),
                                      const LabText('Evaluation block'),
                                      DropdownButton<int>(
                                          key: const ValueKey(
                                              'async-evaluation-chunk'),
                                          value: _chunk,
                                          items: [
                                            for (final v in [8, 32, 128])
                                              DropdownMenuItem(
                                                  value: v,
                                                  child: LabText('$v samples'))
                                          ],
                                          onChanged: _busy
                                              ? null
                                              : (v) =>
                                                  setState(() => _chunk = v!)),
                                    ]),
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const LabText(
                                        'Use an 8 ms work budget'),
                                    subtitle: const LabText(
                                        'Checked between work units; not a frame-time guarantee.'),
                                    value: _budget,
                                    onChanged: _busy
                                        ? null
                                        : (v) => setState(() => _budget = v)),
                              ]),
                        ])),
                const SizedBox(height: 20),
                LabPanel(
                    eyebrow: '02 / TRAIN & OBSERVE',
                    title: 'Your learning session',
                    trailing: LabTag(
                        _busy
                            ? 'Running'
                            : _checkpoint == null
                                ? 'Not started'
                                : 'Saved',
                        color: _busy ? labViolet : labAccent),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            FilledButton.icon(
                                key: const ValueKey('async-start'),
                                onPressed: _busy ? null : () => _run(),
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 18),
                                label: const LabText('Start fresh')),
                            OutlinedButton.icon(
                                key: const ValueKey('async-pause'),
                                onPressed: !_busy ||
                                        _cancelling ||
                                        _status == 'Comparing uninterrupted run'
                                    ? null
                                    : () => _stop(pause: true),
                                icon: const Icon(Icons.pause_rounded, size: 18),
                                label: const LabText('Pause training')),
                            OutlinedButton(
                                key: const ValueKey('async-cancel'),
                                onPressed: !_busy || _cancelling
                                    ? null
                                    : () => _stop(pause: false),
                                child: const LabText('Cancel safely')),
                            OutlinedButton(
                                key: const ValueKey('async-interact'),
                                onPressed: () =>
                                    setState(() => _interactions++),
                                child:
                                    LabText('UI interactions: $_interactions')),
                          ]),
                          const SizedBox(height: 20),
                          Semantics(
                              liveRegion: true,
                              child: LabText(_status,
                                  key: const ValueKey('async-status'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: labAccent))),
                          if (_busy)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: LinearProgressIndicator(
                                    value: p?.fraction ?? 0)),
                          if (_busy && _evaluation != null)
                            LabText(
                                '${_evaluationLabel(_evaluation!.phase)}: ${_evaluation!.samplesCompleted}/${_evaluation!.totalSamples}',
                                key:
                                    const ValueKey('async-evaluation-progress'),
                                style: const TextStyle(
                                    color: labMuted, fontSize: 12)),
                          if (p != null)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Wrap(
                                    spacing: 36,
                                    runSpacing: 16,
                                    children: [
                                      LabMetric(
                                          label: tr(context, 'Epoch'),
                                          value: '${p.epochsCompleted}'),
                                      LabMetric(
                                          label: tr(context, 'Training loss'),
                                          value: p.loss.toStringAsFixed(5)),
                                      LabMetric(
                                          label: tr(context, 'Validation loss'),
                                          value: p.validationLoss
                                                  ?.toStringAsFixed(5) ??
                                              '—',
                                          color: const Color(0xFFF2CA86)),
                                    ])),
                          if (p != null)
                            LabText(
                                'Epoch ${p.epochsCompleted} · loss ${p.loss.toStringAsFixed(6)} · validation ${p.validationLoss?.toStringAsFixed(6)} · ${p.elapsed.inMilliseconds} ms',
                                key: const ValueKey('async-progress'),
                                style: const TextStyle(
                                    color: labMuted, fontSize: 11)),
                          if (_error != null)
                            LabText(_error!,
                                key: const ValueKey('async-run-error'),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          if (_comparison != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: LabText(_comparison!,
                                    key: const ValueKey('async-comparison'),
                                    style: const TextStyle(color: labAccent))),
                          if (_losses.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: LossChart(
                                    training: List.of(_losses),
                                    validation: List.of(_validationLosses)))
                          else
                            const LabEmpty(
                                title: 'The next curve starts here',
                                description:
                                    'Choose a recipe above and start a fresh run to see training and validation evolve together.'),
                          const LabNotice(
                              'Pause and cancel finish the current epoch, then keep a resumable checkpoint. Start fresh replaces it with a newly seeded run.'),
                        ])),
                const SizedBox(height: 20),
                LabPanel(
                    eyebrow: '03 / CONTINUE & REPLAY',
                    title: 'Keep the state, not just the weights',
                    subtitle:
                        'A checkpoint includes the model, Adam state and random seed. Copy the JSON to save it outside this tab.',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_busy && _checkpoint != null) ...[
                            LabText(
                                'Saved epoch: $completed${_elapsed == Duration.zero ? ' · Imported JSON' : ' · last run ${_elapsed.inMilliseconds} ms'}',
                                key: const ValueKey('async-saved'),
                                style: const TextStyle(
                                    color: labAccent,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                          ],
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            OutlinedButton(
                                key: const ValueKey('async-resume'),
                                onPressed: _busy ||
                                        _checkpoint == null ||
                                        completed >= _goal
                                    ? null
                                    : () => _run(resume: true),
                                child: const LabText('Resume checkpoint')),
                            OutlinedButton(
                                key: const ValueKey('async-compare'),
                                onPressed: _busy || completed == 0
                                    ? null
                                    : () => _run(compare: true),
                                child: const LabText('Compare uninterrupted')),
                            OutlinedButton(
                                key: const ValueKey('async-reset'),
                                onPressed: _busy ? null : _reset,
                                child: const LabText('Reset experiment')),
                          ]),
                          if (_checkpoint != null && !_busy) ...[
                            const SizedBox(height: 20),
                            const LabText('First validation predictions',
                                style:
                                    TextStyle(color: labMuted, fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final prediction
                                  in recipe.predictions(_checkpoint!))
                                LabTag(prediction
                                    .map((v) => v.toStringAsFixed(4))
                                    .join(', '))
                            ]),
                          ],
                          const SizedBox(height: 22),
                          TextField(
                              key: const ValueKey('async-json'),
                              controller: _json,
                              enabled: !_busy,
                              minLines: 3,
                              maxLines: 5,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12),
                              decoration: InputDecoration(
                                  labelText: tr(context, 'Checkpoint JSON'),
                                  alignLabelWithHint: true)),
                          if (_importError != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Semantics(
                                    liveRegion: true,
                                    child: LabText(_importError!,
                                        key: const ValueKey('async-error'),
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error)))),
                          const SizedBox(height: 14),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            OutlinedButton(
                                key: const ValueKey('async-copy'),
                                onPressed: _busy || _checkpoint == null
                                    ? null
                                    : () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: _json.text));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: LabText(
                                                      'Checkpoint copied. Save it before closing the tab.')));
                                        }
                                      },
                                child: const LabText('Copy checkpoint JSON')),
                            OutlinedButton(
                                key: const ValueKey('async-load'),
                                onPressed: _busy ? null : _load,
                                child: const LabText('Load checkpoint JSON')),
                          ]),
                        ])),
                const LabNotice(
                    'Browser runs yield between batches and evaluation blocks. An indivisible work unit can still take a frame. Exact replay needs the same recipe, runtime and platform; SOM has a separate unsupervised schedule.'),
              ],
            )));
  }
}

String _evaluationLabel(TrainingPhase phase) => switch (phase) {
      TrainingPhase.trainingPreflight => 'Checking training data',
      TrainingPhase.validationPreflight => 'Checking validation data',
      TrainingPhase.trainingEvaluation => 'Measuring training loss',
      TrainingPhase.validationEvaluation => 'Measuring validation loss',
      _ => 'Evaluation',
    };

import 'dart:async';
import 'dart:convert';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neural_engine/neural_engine.dart';

import '../runners/async_demo_recipe.dart';
import '../widgets/loss_chart.dart';

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
  String? _error, _comparison;
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
        _losses.clear();
        _validationLosses.clear();
        _progress = null;
        _comparison = null;
        _error = null;
        _status = 'Loaded at epoch ${checkpoint.epochsCompleted}';
      });
    } catch (error) {
      setState(() => _error = 'Checkpoint rejected: $error');
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
          _error = '$error';
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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
                key: const ValueKey('async-scroll'),
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Train without blocking the interface',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Text(
                      'Native: dedicated isolate. Web: cooperative mini-batches. Cancel completes the current epoch '
                      'and saves model + Adam state. Pause uses the same safe boundary; Resume continues from that checkpoint. '
                      'Start fresh discards the saved run. Copy JSON before closing the app.'),
                  Wrap(
                      spacing: 24,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DropdownButton<String>(
                            key: const ValueKey('async-family'),
                            value: _family,
                            items: [
                              for (final name in [
                                'MLP',
                                'CNN',
                                'RNN',
                                'LSTM',
                                'GRU',
                                'Autoencoder',
                              ])
                                DropdownMenuItem(
                                    value: name, child: Text(name)),
                            ],
                            onChanged: _busy
                                ? null
                                : (v) => setState(() {
                                      _family = v!;
                                      _checkpoint = null;
                                      _progress = null;
                                      _comparison = null;
                                      _losses.clear();
                                      _validationLosses.clear();
                                      _json.clear();
                                      _error = null;
                                      _status = 'Ready';
                                    })),
                        Text('Target total epochs: $_goal'),
                      ]),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(recipe.architecture,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text(
                                    '${recipe.inputs.length} training · ${recipe.validationInputs.length} validation samples'),
                                Text(
                                    'Adam · learning rate 0.02 · batch ${recipe.batchSize} · seed 42 · gradient clip 1'),
                                Text('Loss: ${recipe.loss.name}'),
                                Text(recipe.dataDescription),
                              ]))),
                  Slider(
                      key: const ValueKey('async-epochs'),
                      semanticFormatterCallback: (v) =>
                          '${v.round()} target epochs',
                      value: _goal.toDouble(),
                      min: 10,
                      max: 1000,
                      divisions: 99,
                      onChanged: _busy || _checkpoint != null
                          ? null
                          : (v) => setState(() => _goal = v.round())),
                  Wrap(
                      spacing: 24,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Batches per UI yield'),
                        DropdownButton<int>(
                            key: const ValueKey('async-frequency'),
                            value: _frequency,
                            items: [
                              for (final value in [1, 4, 16])
                                DropdownMenuItem(
                                    value: value,
                                    child: Text('$value batches')),
                            ],
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _frequency = v!)),
                        const Text('Evaluation samples per block'),
                        DropdownButton<int>(
                            key: const ValueKey('async-evaluation-chunk'),
                            value: _chunk,
                            items: [
                              for (final value in [8, 32, 128])
                                DropdownMenuItem(
                                    value: value,
                                    child: Text('$value samples')),
                            ],
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _chunk = v!)),
                      ]),
                  SwitchListTile(
                      title: const Text('Use an 8 ms work budget'),
                      subtitle: const Text(
                          'Checked between batches and evaluation blocks; not a frame-time guarantee.'),
                      value: _budget,
                      onChanged:
                          _busy ? null : (v) => setState(() => _budget = v)),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    FilledButton(
                        key: const ValueKey('async-start'),
                        onPressed: _busy ? null : () => _run(),
                        child: const Text('Start fresh')),
                    OutlinedButton(
                        key: const ValueKey('async-pause'),
                        onPressed: !_busy ||
                                _cancelling ||
                                _status == 'Comparing uninterrupted run'
                            ? null
                            : () => _stop(pause: true),
                        child: const Text('Pause training')),
                    OutlinedButton(
                        key: const ValueKey('async-reset'),
                        onPressed: _busy ? null : _reset,
                        child: const Text('Reset experiment')),
                    OutlinedButton(
                        key: const ValueKey('async-cancel'),
                        onPressed: !_busy || _cancelling
                            ? null
                            : () => _stop(pause: false),
                        child: const Text('Cancel safely')),
                    OutlinedButton(
                        key: const ValueKey('async-resume'),
                        onPressed:
                            _busy || _checkpoint == null || completed >= _goal
                                ? null
                                : () => _run(resume: true),
                        child: const Text('Resume checkpoint')),
                    OutlinedButton(
                        key: const ValueKey('async-compare'),
                        onPressed: _busy || completed == 0
                            ? null
                            : () => _run(compare: true),
                        child: const Text('Compare uninterrupted')),
                    OutlinedButton(
                        key: const ValueKey('async-interact'),
                        onPressed: () => setState(() => _interactions++),
                        child: Text('UI interactions: $_interactions')),
                  ]),
                  const SizedBox(height: 12),
                  Semantics(
                      liveRegion: true,
                      child:
                          Text(_status, key: const ValueKey('async-status'))),
                  if (_busy && _evaluation != null)
                    Text(
                        '${_evaluationLabel(_evaluation!.phase)}: ${_evaluation!.samplesCompleted}/${_evaluation!.totalSamples}',
                        key: const ValueKey('async-evaluation-progress')),
                  if (_busy) LinearProgressIndicator(value: p?.fraction ?? 0),
                  if (p != null)
                    Text(
                        'Epoch ${p.epochsCompleted} · loss ${p.loss.toStringAsFixed(6)} · '
                        'validation ${p.validationLoss?.toStringAsFixed(6)} · ${p.elapsed.inMilliseconds} ms',
                        key: const ValueKey('async-progress')),
                  if (!_busy && _checkpoint != null)
                    Text(
                        'Saved epoch: $completed · last run ${_elapsed.inMilliseconds} ms',
                        key: const ValueKey('async-saved')),
                  if (_error != null)
                    Text(_error!, key: const ValueKey('async-error')),
                  if (_comparison != null)
                    Text(_comparison!, key: const ValueKey('async-comparison')),
                  if (_losses.isNotEmpty)
                    LossChart(
                        training: List.of(_losses),
                        validation: List.of(_validationLosses)),
                  if (_checkpoint != null && !_busy) ...[
                    const Text('First validation predictions'),
                    for (final prediction
                        in AsyncDemoRecipe(_family).predictions(_checkpoint!))
                      Text(prediction
                          .map((v) => v.toStringAsFixed(4))
                          .join(', ')),
                  ],
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, children: [
                    OutlinedButton(
                        key: const ValueKey('async-copy'),
                        onPressed: _busy || _checkpoint == null
                            ? null
                            : () async {
                                await Clipboard.setData(
                                    ClipboardData(text: _json.text));
                              },
                        child: const Text('Copy checkpoint JSON')),
                    OutlinedButton(
                        key: const ValueKey('async-load'),
                        onPressed: _busy ? null : _load,
                        child: const Text('Load checkpoint JSON')),
                  ]),
                  TextField(
                      key: const ValueKey('async-json'),
                      controller: _json,
                      enabled: !_busy,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          labelText: 'Checkpoint JSON',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  const Text(
                      'MLP validation reuses XOR; other recipes use different synthetic noise/phases. '
                      'Exact replay requires the same runtime and platform. SOM uses its own unsupervised schedule. '
                      'Web yields between batches and evaluation blocks. A large indivisible unit can still take a frame. '
                      'Copy JSON explicitly to retain it after closing the app.'),
                ])));
  }
}

String _evaluationLabel(TrainingPhase phase) => switch (phase) {
      TrainingPhase.trainingPreflight => 'Checking training data',
      TrainingPhase.validationPreflight => 'Checking validation data',
      TrainingPhase.trainingEvaluation => 'Measuring training loss',
      TrainingPhase.validationEvaluation => 'Measuring validation loss',
      _ => 'Evaluation',
    };

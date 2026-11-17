// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:neural_engine/neural_engine.dart';
import '../runners/mlp_runner.dart';
import '../data/xor_dataset.dart';
import '../widgets/plot_panel.dart';
import '../painters/loss_painter.dart';
import '../painters/boundary_painter.dart';

class MlpPage extends StatefulWidget {
  const MlpPage({super.key});
  @override
  State<MlpPage> createState() => _MlpPageState();
}

class _MlpPageState extends State<MlpPage> {
  double _units = 8;
  double _rate = 0.03;
  bool _busy = false;
  NeuralNetwork? _network;
  List<double> _losses = [];
  String? _error;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await compute(trainXor, {'units': _units, 'rate': _rate});
      if (!mounted) return;
      setState(() {
        _network =
            NeuralNetwork.fromJson(result['model']! as Map<String, dynamic>);
        _losses = (result['losses']! as List<double>);
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Text('Teach a network to separate XOR',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Two inputs → tanh hidden layer → sigmoid output. Seed 42 · Adam · 800 epochs.'),
                  const SizedBox(height: 24),
                  Text('Hidden neurons: ${_units.round()}'),
                  Slider(
                      value: _units,
                      semanticFormatterCallback: (v) =>
                          '${v.round()} hidden neurons',
                      min: 2,
                      max: 16,
                      divisions: 14,
                      label: '${_units.round()}',
                      onChanged:
                          _busy ? null : (v) => setState(() => _units = v)),
                  Text('Learning rate: ${_rate.toStringAsFixed(3)}'),
                  Slider(
                      value: _rate,
                      semanticFormatterCallback: (v) =>
                          'Learning rate ${v.toStringAsFixed(3)}',
                      min: 0.005,
                      max: 0.1,
                      divisions: 19,
                      label: _rate.toStringAsFixed(3),
                      onChanged:
                          _busy ? null : (v) => setState(() => _rate = v)),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                          onPressed: _busy ? null : _run,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_busy ? 'Training…' : 'Train network'))),
                  if (_busy)
                    const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: LinearProgressIndicator()),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 24),
                  if (_network == null)
                    const Text(
                        'Train to see the loss curve, decision surface and predictions.'),
                  if (_network != null) ...[
                    Text(
                        'Final binary cross entropy: ${_losses.last.toStringAsFixed(6)}'),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, constraints) {
                      final plots = [
                        PlotPanel(
                            title: 'Loss by epoch',
                            painter: LossPainter(_losses)),
                        PlotPanel(
                            title: 'Decision surface • blue = 0, orange = 1',
                            painter: BoundaryPainter(_network!)),
                      ];
                      return constraints.maxWidth > 700
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Expanded(child: plots[0]),
                                  const SizedBox(width: 24),
                                  Expanded(child: plots[1])
                                ])
                          : Column(children: [
                              plots[0],
                              const SizedBox(height: 24),
                              plots[1]
                            ]);
                    }),
                    const SizedBox(height: 24),
                    for (var i = 0; i < 4; i++)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                              '${xorInputs[i]} → ${_network!.predict(xorInputs[i]).single.toStringAsFixed(4)}  |  target ${xorTargets[i].single.toInt()}')),
                    const SizedBox(height: 16),
                    const Text(
                        'Plots show the last completed run. Changing controls takes effect on the next training run.'),
                  ],
                ]))),
      );
}

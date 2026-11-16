import 'dart:math' as math;
import 'package:flutter/foundation.dart';
// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:neural_engine/neural_engine.dart';

void main() => runApp(const NeuralLab());

class NeuralLab extends StatelessWidget {
  const NeuralLab({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Neural Engine Lab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.cyan,
            useMaterial3: true),
        home: const LabPage(),
      );
}

const _inputs = <List<double>>[
  [0, 0],
  [0, 1],
  [1, 0],
  [1, 1]
];
const _targets = <List<double>>[
  [0],
  [1],
  [1],
  [0]
];

Map<String, Object?> _train(Map<String, num> config) {
  final network = NeuralNetwork(inputSize: 2, seed: 42, layers: [
    Dense(config['units']!.toInt(), activation: Activation.tanh),
    Dense(1, activation: Activation.sigmoid),
  ]);
  final history = network.fit(
      inputs: _inputs,
      targets: _targets,
      loss: const BinaryCrossEntropy(),
      optimizer: Adam(learningRate: config['rate']!.toDouble()),
      epochs: 800,
      batchSize: 4);
  return {'model': network.toJson(), 'losses': history.losses};
}

class LabPage extends StatefulWidget {
  const LabPage({super.key});
  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
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
      final result = await compute(_train, {'units': _units, 'rate': _rate});
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
        appBar: AppBar(title: const Text('Neural Engine • XOR Lab')),
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
                      min: 2,
                      max: 16,
                      divisions: 14,
                      label: '${_units.round()}',
                      onChanged:
                          _busy ? null : (v) => setState(() => _units = v)),
                  Text('Learning rate: ${_rate.toStringAsFixed(3)}'),
                  Slider(
                      value: _rate,
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
                        _Plot(
                            title: 'Loss by epoch',
                            painter: _LossPainter(_losses)),
                        _Plot(
                            title: 'Decision surface • blue = 0, orange = 1',
                            painter: _BoundaryPainter(_network!)),
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
                              '${_inputs[i]} → ${_network!.predict(_inputs[i]).single.toStringAsFixed(4)}  |  target ${_targets[i].single.toInt()}')),
                    const SizedBox(height: 16),
                    const Text(
                        'Plots show the last completed run. Changing controls takes effect on the next training run.'),
                  ],
                ]))),
      );
}

class _Plot extends StatelessWidget {
  final String title;
  final CustomPainter painter;
  const _Plot({required this.title, required this.painter});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title),
        const SizedBox(height: 12),
        AspectRatio(aspectRatio: 1.25, child: CustomPaint(painter: painter)),
      ]);
}

class _LossPainter extends CustomPainter {
  final List<double> losses;
  _LossPainter(this.losses);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke;
    final area = Rect.fromLTWH(38, 12, size.width - 50, size.height - 40);
    canvas.drawRect(area, paint);
    final maxLoss = math.max(0.01, losses.reduce(math.max));
    final path = Path();
    for (var i = 0; i < losses.length; i++) {
      final x = area.left + area.width * i / math.max(1, losses.length - 1);
      final y = area.bottom - area.height * losses[i] / maxLoss;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    _text(canvas, maxLoss.toStringAsFixed(2), Offset(0, area.top));
    _text(canvas, '0', Offset(18, area.bottom - 12));
    _text(canvas, '1', Offset(area.left, area.bottom + 8));
    _text(canvas, '${losses.length} epochs',
        Offset(area.right - 85, area.bottom + 8));
  }

  @override
  bool shouldRepaint(_LossPainter old) => !identical(losses, old.losses);
}

class _BoundaryPainter extends CustomPainter {
  final NeuralNetwork network;
  _BoundaryPainter(this.network);
  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(30, 12, size.width - 45, size.height - 40);
    const cells = 36;
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final p =
            network.predict([x / (cells - 1), 1 - y / (cells - 1)]).single;
        canvas.drawRect(
            Rect.fromLTWH(
                area.left + x * area.width / cells,
                area.top + y * area.height / cells,
                area.width / cells + 0.5,
                area.height / cells + 0.5),
            Paint()
              ..color = Color.lerp(
                  Colors.blue.shade800, Colors.deepOrange.shade400, p)!);
      }
    }
    for (var i = 0; i < 4; i++) {
      final position = Offset(area.left + _inputs[i][0] * area.width,
          area.bottom - _inputs[i][1] * area.height);
      canvas.drawCircle(position, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
          position,
          5,
          Paint()
            ..color = _targets[i][0] == 0 ? Colors.blue : Colors.deepOrange);
    }
    _text(canvas, 'x₂', Offset(0, area.top));
    _text(canvas, '0', Offset(area.left, area.bottom + 8));
    _text(canvas, '1 · x₁', Offset(area.right - 32, area.bottom + 8));
  }

  @override
  bool shouldRepaint(_BoundaryPainter old) => network != old.network;
}

void _text(Canvas canvas, String text, Offset offset) {
  final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      textDirection: TextDirection.ltr)
    ..layout();
  painter.paint(canvas, offset);
}

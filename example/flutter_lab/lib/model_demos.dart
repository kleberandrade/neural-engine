import 'dart:math' as math;
import 'package:flutter/foundation.dart';
// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:neural_engine/neural_engine.dart';
import 'datasets.dart';

enum DemoKind { som, cnn, autoencoder }

Map<String, Object?> _runModel(String name) {
  if (name == 'som') {
    final samples = colorDataset();
    final model =
        SelfOrganizingMap(rows: 6, columns: 6, inputSize: 3, seed: 42);
    final before = model.weights;
    final initial = model.quantizationError(samples);
    final history = model.fit(samples, epochs: 80, radius: 3, finalRadius: 0.4);
    return {
      'curve': history.quantizationErrors,
      'before': before,
      'weights': model.weights,
      'summary':
          'Quantization error: ${initial.toStringAsFixed(4)} → ${history.quantizationErrors.last.toStringAsFixed(4)}',
      'matches': [
        for (final color in <List<double>>[
          [1, 0, 0],
          [0, 1, 0],
          [0, 0, 1]
        ])
          'RGB $color → (${model.winner(color).row}, ${model.winner(color).column})'
      ]
    };
  }
  if (name == 'cnn') {
    final train = barDataset();
    final test = barDataset(seed: 99, repetitions: 1);
    final model = ConvolutionalNetwork(
        inputHeight: 6,
        inputWidth: 6,
        seed: 42,
        layers: [
          Conv2D(filters: 4, padding: ConvolutionPadding.same),
          MaxPool2D()
        ],
        denseLayers: [
          Dense(2, activation: Activation.softmax)
        ]);
    final history = model.fit(
        inputs: train.images,
        targets: train.targets,
        loss: const CategoricalCrossEntropy(),
        optimizer: Adam(learningRate: 0.02),
        epochs: 100,
        batchSize: 8);
    return {
      'curve': history.losses,
      'summary': 'Conv2D 6×6×4 → MaxPool 3×3×4 → Flatten 36 → Dense 2',
      'samples': [
        for (var i = 0; i < test.images.length; i++)
          <String, Object>{
            'input': test.images[i].values,
            'target': test.targets[i],
            'prediction': model.predict(test.images[i]),
            'features': model.featureMaps(test.images[i]).first.values,
          }
      ]
    };
  }
  final train = reconstructionDataset();
  final test = reconstructionDataset(seed: 99);
  final model = NeuralNetwork(inputSize: 8, seed: 42, layers: [
    Dense(6, activation: Activation.tanh),
    Dense(2, activation: Activation.tanh),
    Dense(6, activation: Activation.tanh),
    Dense(8, activation: Activation.sigmoid)
  ]);
  final history = model.fit(
      inputs: train.inputs,
      targets: train.targets,
      loss: const BinaryCrossEntropy(),
      optimizer: Adam(learningRate: 0.02),
      epochs: 400,
      batchSize: 8);
  return {
    'curve': history.losses,
    'summary':
        'Held-out reconstruction MSE: ${model.evaluate(inputs: test.inputs, targets: test.targets, loss: const MeanSquaredError()).toStringAsFixed(6)}',
    'samples': [
      for (var i = 0; i < test.inputs.length; i += 5)
        <String, Object>{
          'input': test.inputs[i],
          'target': test.targets[i],
          'prediction': model.predict(test.inputs[i]),
          'latent': model.layerOutputs(test.inputs[i])[1],
        }
    ]
  };
}

class ModelDemo extends StatefulWidget {
  final DemoKind kind;
  const ModelDemo({required this.kind, super.key});
  @override
  State<ModelDemo> createState() => _ModelDemoState();
}

class _ModelDemoState extends State<ModelDemo>
    with AutomaticKeepAliveClientMixin {
  Map<String, Object?>? _result;
  bool _busy = false;
  String? _error;
  int _sample = 0;
  int _channel = 0;
  @override
  bool get wantKeepAlive => true;

  Future<void> _train() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await compute(_runModel, widget.kind.name);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSom = widget.kind == DemoKind.som;
    final isCnn = widget.kind == DemoKind.cnn;
    final title = isSom
        ? 'SOM • organize colors without labels'
        : isCnn
            ? 'CNN • recognize vertical and horizontal bars'
            : 'Autoencoder • reconstruct a clean pattern';
    final explanation = isSom
        ? 'Each cell is a learned RGB prototype. The best matching unit and its grid neighbors move toward each sample. Nearby cells tend to represent similar colors; cell coordinates are not class labels.'
        : isCnn
            ? 'A shared 3×3 filter scans the image, ReLU creates feature maps, max pooling reduces spatial dimensions, and a dense softmax head predicts the orientation. Filters and head train together.'
            : 'An encoder compresses 8 values into 2 latent coordinates. A decoder reconstructs the 8 clean target values from noisy input. This example uses ordinary Dense layers with no tied weights.';
    final result = _result;
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
                key: PageStorageKey(widget.kind),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(explanation),
                  const SizedBox(height: 12),
                  const Text(
                      'Deterministic synthetic data · seed 42 · CPU training · educational example'),
                  const SizedBox(height: 16),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                          key: ValueKey('train-${widget.kind.name}'),
                          onPressed: _busy ? null : _train,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_busy
                              ? 'Training…'
                              : 'Train ${widget.kind.name}'))),
                  if (_busy)
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child: LinearProgressIndicator()),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  if (result != null) ...[
                    const SizedBox(height: 20),
                    Text(result['summary']! as String,
                        key: ValueKey('result-${widget.kind.name}')),
                    const SizedBox(height: 16),
                    Text(isSom
                        ? 'Quantization error per epoch (Euclidean distance)'
                        : 'Training cross entropy per epoch'),
                    SizedBox(
                        height: 160,
                        child: CustomPaint(
                            painter: _Curve(result['curve']! as List<double>))),
                    const SizedBox(height: 24),
                    if (isSom) ...[
                      Wrap(spacing: 24, runSpacing: 16, children: [
                        _ColorMap(
                            title: 'Before training',
                            weights: result['before']! as List<List<double>>),
                        _ColorMap(
                            title: 'After training',
                            weights: result['weights']! as List<List<double>>),
                      ]),
                      const SizedBox(height: 16),
                      for (final match in result['matches']! as List<String>)
                        Text(match),
                    ] else
                      ..._sampleWidgets(result, isCnn),
                    const SizedBox(height: 24),
                    Text(isSom
                        ? 'Read the SOM tutorial in doc/models.pt-BR.md. Try changing the grid/radius in the Dart example and compare topology, not only error.'
                        : isCnn
                            ? 'Test images use a different noise seed but the same bar positions. This does not measure performance on real photos or unseen shape families. Feature maps below use per-channel min/max contrast.'
                            : 'The test set changes noise on four familiar patterns. A low reconstruction error here does not establish anomaly detection or compression quality on real data.'),
                  ],
                ])));
  }

  List<Widget> _sampleWidgets(Map<String, Object?> result, bool cnn) {
    final samples = result['samples']! as List<Map<String, Object>>;
    final sample = samples[_sample];
    final prediction = sample['prediction']! as List<double>;
    return [
      Text('Test sample ${_sample + 1}/${samples.length}'),
      Slider(
          value: _sample.toDouble(),
          min: 0,
          max: (samples.length - 1).toDouble(),
          divisions: samples.length - 1,
          onChanged: (v) => setState(() => _sample = v.round())),
      if (cnn)
        Text(
            'Target: ${(sample['target']! as List<double>)[0] == 1 ? 'vertical' : 'horizontal'} · predicted probabilities [vertical, horizontal]: ${prediction.map((v) => v.toStringAsFixed(4)).join(', ')}'),
      if (!cnn)
        Text(
            'Latent coordinates: ${(sample['latent']! as List<double>).map((v) => v.toStringAsFixed(3)).join(', ')}'),
      const SizedBox(height: 12),
      Wrap(spacing: 24, runSpacing: 16, children: [
        _Pixels(
            title: 'Input',
            values: sample['input']! as List<double>,
            columns: cnn ? 6 : 4),
        if (!cnn)
          _Pixels(
              title: 'Clean target',
              values: sample['target']! as List<double>,
              columns: 4),
        if (!cnn)
          _Pixels(title: 'Reconstruction', values: prediction, columns: 4),
        if (cnn)
          _Pixels(
              title: 'Convolution channel $_channel',
              values: _normalize(List.generate(
                  36,
                  (i) =>
                      (sample['features']! as List<double>)[i * 4 + _channel])),
              columns: 6),
      ]),
      if (cnn) ...[
        const SizedBox(height: 12),
        const Text('Inspect filter channel'),
        Slider(
            value: _channel.toDouble(),
            min: 0,
            max: 3,
            divisions: 3,
            label: '$_channel',
            onChanged: (v) => setState(() => _channel = v.round())),
      ],
    ];
  }
}

List<double> _normalize(List<double> values) {
  final low = values.reduce(math.min);
  final high = values.reduce(math.max);
  return values
      .map((v) => high == low ? 0.0 : (v - low) / (high - low))
      .toList();
}

class _Pixels extends StatelessWidget {
  final String title;
  final List<double> values;
  final int columns;
  const _Pixels(
      {required this.title, required this.values, required this.columns});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 210,
      child: Column(children: [
        Text(title),
        const SizedBox(height: 8),
        GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            children: [
              for (final v in values)
                ColoredBox(
                    color: Color.lerp(
                        Colors.black, Colors.cyanAccent, v.clamp(0.0, 1.0))!)
            ]),
      ]));
}

class _ColorMap extends StatelessWidget {
  final String title;
  final List<List<double>> weights;
  const _ColorMap({required this.title, required this.weights});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 260,
      child: Column(children: [
        Text(title),
        const SizedBox(height: 8),
        GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            children: [
              for (final w in weights)
                Tooltip(
                    message: w.map((v) => v.toStringAsFixed(2)).join(', '),
                    child: ColoredBox(
                        color: Color.fromRGBO(
                            (w[0] * 255).round().clamp(0, 255),
                            (w[1] * 255).round().clamp(0, 255),
                            (w[2] * 255).round().clamp(0, 255),
                            1)))
            ]),
      ]));
}

class _Curve extends CustomPainter {
  final List<double> values;
  _Curve(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(1e-9, values.reduce(math.max));
    final area = Rect.fromLTWH(42, 14, size.width - 56, size.height - 40);
    canvas.drawRect(
        area,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = area.left + area.width * i / math.max(1, values.length - 1);
      final y = area.bottom - area.height * values[i] / maxValue;
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
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    for (final item in [
      (maxValue.toStringAsFixed(3), Offset(0, area.top)),
      ('0', Offset(22, area.bottom - 10)),
      ('1', Offset(area.left, area.bottom + 6)),
      ('${values.length} epochs', Offset(area.right - 90, area.bottom + 6))
    ]) {
      final text = TextPainter(
          text: TextSpan(
              text: item.$1,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(canvas, item.$2);
    }
  }

  @override
  bool shouldRepaint(_Curve old) => !identical(values, old.values);
}

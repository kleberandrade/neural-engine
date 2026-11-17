// Keep compatibility with Flutter versions before the material_ui split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:neural_engine/neural_engine.dart';

import '../data/demo_kind.dart';
import '../runners/demo_runner.dart';
import '../painters/curve_painter.dart';
import '../widgets/color_map.dart';
import '../widgets/pixel_grid.dart';
import '../widgets/scalar_grid.dart';
import '../widgets/drawing_classifier.dart';

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
      final result = await compute(trainDemo, widget.kind.name);
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
                  Text(isSom
                      ? '6×6 map · 80 epochs · learning rate 0.5 → 0.05 · radius 3 → 0.4'
                      : isCnn
                          ? '16 training / 8 test images · Adam 0.02 · batch 8 · 100 epochs · categorical cross entropy'
                          : '20 training / 20 test patterns · Adam 0.02 · batch 8 · 400 epochs · binary cross entropy'),
                  const Text(
                      'For live progress and safe stop/resume of supervised models, open Async training.'),
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
                    if (isCnn)
                      Text(
                          'Held-out noise accuracy: ${((result['testAccuracy']! as double) * 100).toStringAsFixed(1)}%'),
                    const SizedBox(height: 16),
                    Text(isSom
                        ? 'Quantization error per epoch (Euclidean distance)'
                        : 'Training cross entropy per epoch'),
                    SizedBox(
                        height: 160,
                        child: CustomPaint(
                            painter: CurvePainter(
                                result['curve']! as List<double>))),
                    const SizedBox(height: 24),
                    if (isSom) ...[
                      Wrap(spacing: 24, runSpacing: 16, children: [
                        ColorMap(
                            title: 'Before training',
                            weights: result['before']! as List<List<double>>),
                        ColorMap(
                            title: 'After training',
                            weights: result['weights']! as List<List<double>>),
                      ]),
                      const SizedBox(height: 16),
                      ScalarGrid(
                          title: 'U-matrix: neighbor distance',
                          values: result['distances']! as List<double>,
                          columns: 6),
                      ScalarGrid(
                          title: 'BMU sample counts',
                          values: result['hits']! as List<double>,
                          columns: 6),
                      for (final match in result['matches']! as List<String>)
                        Text(match),
                    ] else
                      ..._sampleWidgets(result, isCnn),
                    if (isCnn)
                      DrawingClassifier(
                          model: ConvolutionalNetwork.fromJson(
                              result['model']! as Map<String, dynamic>)),
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
          semanticFormatterCallback: (v) =>
              'Test sample ${v.round() + 1} of ${samples.length}',
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
        PixelGrid(
            title: 'Input',
            values: sample['input']! as List<double>,
            columns: cnn ? 6 : 4),
        if (!cnn)
          PixelGrid(
              title: 'Clean target',
              values: sample['target']! as List<double>,
              columns: 4),
        if (!cnn)
          PixelGrid(title: 'Reconstruction', values: prediction, columns: 4),
        if (cnn)
          PixelGrid(
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
            semanticFormatterCallback: (v) =>
                'Convolution channel ${v.round()}',
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

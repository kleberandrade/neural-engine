import '../l10n/lab_copy.dart';
import 'package:material_ui/material_ui.dart';

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
import '../widgets/lab_design.dart';

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
      if (mounted) {
        setState(() =>
            _error = 'Training failed. Try a fresh run with these settings.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSom = widget.kind == DemoKind.som;
    final isCnn = widget.kind == DemoKind.cnn;
    final result = _result;
    final title = isSom
        ? 'Similar colors.\nShared neighborhoods.'
        : isCnn
            ? 'Small filters.\nA different way to see.'
            : 'Less information.\nA familiar pattern.';
    final description = isSom
        ? 'Watch a map organize RGB colors without labels. Nearby prototypes learn to represent similar inputs.'
        : isCnn
            ? 'Train a convolutional network to recognize vertical and horizontal bars. Inspect the filters, then test your own drawing.'
            : 'Compress a noisy pattern to two coordinates, then reconstruct a clean target. Explore what the bottleneck keeps.';
    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              key: PageStorageKey(widget.kind),
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 32),
              children: [
                LabHeader(
                    kicker: isSom
                        ? '02 / Self-organizing map'
                        : isCnn
                            ? '03 / Convolutional network'
                            : '04 / Autoencoder',
                    title: title,
                    description: description,
                    tags: [
                      LabTag(
                          isSom
                              ? 'Unsupervised learning'
                              : isCnn
                                  ? 'Image classification'
                                  : 'Denoising',
                          color: labAccent),
                      const LabTag('Synthetic data'),
                      const LabTag('Seed 42', color: labViolet)
                    ]),
                LabPanel(
                    eyebrow: '01 / THE RECIPE',
                    title: isSom
                        ? 'A map of color space'
                        : isCnn
                            ? 'From pixels to probabilities'
                            : 'Encode, compress, decode',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final stage in isSom
                                ? [
                                    'RGB · 3 features',
                                    '6×6 prototypes',
                                    'Gaussian neighborhood'
                                  ]
                                : isCnn
                                    ? [
                                        '6×6×1 input',
                                        '3×3 convolution · 4 filters',
                                        'Max pooling',
                                        '2-class softmax'
                                      ]
                                    : [
                                        '8 inputs',
                                        '6 hidden',
                                        '2 latent',
                                        '6 hidden',
                                        '8 outputs'
                                      ])
                              LabTag(stage, color: labViolet)
                          ]),
                          const SizedBox(height: 18),
                          LabText(
                              isSom
                                  ? '80 epochs · learning rate 0.5 → 0.05 · radius 3 → 0.4'
                                  : isCnn
                                      ? '16 training / 8 test images · Adam 0.02 · batch 8 · 100 epochs · categorical cross entropy'
                                      : '20 training / 20 test patterns · Adam 0.02 · batch 8 · 400 epochs · binary cross entropy',
                              style: const TextStyle(
                                  color: labMuted, height: 1.6)),
                          const SizedBox(height: 20),
                          Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilledButton.icon(
                                    key: ValueKey('train-${widget.kind.name}'),
                                    onPressed: _busy ? null : _train,
                                    icon: const Icon(Icons.play_arrow_rounded,
                                        size: 18),
                                    label: LabText(_busy
                                        ? 'Training…'
                                        : 'Train ${isSom ? 'SOM' : isCnn ? 'CNN' : 'autoencoder'}')),
                                if (!isSom &&
                                    LabNavigation.maybeOf(context) != null)
                                  TextButton(
                                      onPressed: () =>
                                          LabNavigation.maybeOf(context)!
                                              .select(6),
                                      child: const LabText(
                                          'Open live training →')),
                              ]),
                          if (_busy)
                            const Padding(
                                padding: EdgeInsets.only(top: 18),
                                child: LinearProgressIndicator()),
                          if (_error != null)
                            LabNotice(_error!, icon: Icons.error_outline),
                          if (result != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: LabText(result['summary']! as String,
                                    key: ValueKey('result-${widget.kind.name}'),
                                    style: const TextStyle(
                                        color: labAccent,
                                        fontWeight: FontWeight.w600))),
                        ])),
                const SizedBox(height: 20),
                if (result == null)
                  LabPanel(
                      eyebrow: '02 / OBSERVE',
                      title: 'Make the invisible visible',
                      child: LabEmpty(
                          icon: isSom
                              ? Icons.grid_view_rounded
                              : isCnn
                                  ? Icons.filter_center_focus_rounded
                                  : Icons.unfold_less_rounded,
                          title: isSom
                              ? 'A neighborhood waiting to form'
                              : isCnn
                                  ? 'Let the filters learn'
                                  : 'Find the two-value representation',
                          description: isSom
                              ? 'Train the map to compare its initial and learned prototypes, neighborhood distances and sample hits.'
                              : isCnn
                                  ? 'After training, compare held-out probabilities, explore a feature channel and draw a new pattern.'
                                  : 'After training, compare noisy inputs with clean targets, reconstructions and latent coordinates.')),
                if (result != null) ...[
                  LabPanel(
                      eyebrow: '02 / LEARNING CURVE',
                      title: isSom ? 'Quantization error' : 'Training loss',
                      subtitle: isSom
                          ? 'Euclidean distance to the winning prototype · lower is better'
                          : 'Cross entropy over completed epochs',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(spacing: 40, runSpacing: 16, children: [
                              LabMetric(
                                  label: isSom
                                      ? 'Final quantization error'
                                      : 'Final training loss',
                                  value: (result['curve']! as List<double>)
                                      .last
                                      .toStringAsFixed(5)),
                              if (isCnn)
                                LabMetric(
                                    label:
                                        tr(context, 'Held-out noise accuracy'),
                                    value:
                                        '${((result['testAccuracy']! as double) * 100).toStringAsFixed(1)}%',
                                    color: labViolet),
                            ]),
                            const SizedBox(height: 24),
                            SizedBox(
                                height: 190,
                                width: double.infinity,
                                child: Semantics(
                                    image: true,
                                    label: tr(context,
                                        '${isSom ? 'Quantization error' : 'Training loss'} over ${(result['curve']! as List<double>).length} epochs'),
                                    child: CustomPaint(
                                        painter: CurvePainter(
                                            result['curve']! as List<double>,
                                            epochLabel:
                                                tr(context, 'epochs'))))),
                          ])),
                  const SizedBox(height: 20),
                  LabPanel(
                      eyebrow: '03 / EXPLORE THE RESULT',
                      title: isSom
                          ? 'Color space, organized'
                          : isCnn
                              ? 'Inspect an image and its features'
                              : 'What did the bottleneck preserve?',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSom) ...[
                              Wrap(spacing: 32, runSpacing: 24, children: [
                                ColorMap(
                                    title: 'Before training',
                                    weights: result['before']!
                                        as List<List<double>>),
                                ColorMap(
                                    title: 'After training',
                                    weights: result['weights']!
                                        as List<List<double>>)
                              ]),
                              const SizedBox(height: 24),
                              Wrap(spacing: 32, runSpacing: 24, children: [
                                ScalarGrid(
                                    title: 'U-matrix: neighbor distance',
                                    values:
                                        result['distances']! as List<double>,
                                    columns: 6),
                                ScalarGrid(
                                    title: 'BMU sample counts',
                                    values: result['hits']! as List<double>,
                                    columns: 6)
                              ]),
                              const SizedBox(height: 20),
                              for (final match
                                  in result['matches']! as List<String>)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: LabText(match,
                                        style: const TextStyle(
                                            color: labMuted, fontSize: 12))),
                            ] else
                              ..._sampleWidgets(result, isCnn),
                          ])),
                  if (isCnn) ...[
                    const SizedBox(height: 20),
                    LabPanel(
                        eyebrow: '04 / TRY YOUR OWN',
                        title: 'Does your pattern look familiar?',
                        child: DrawingClassifier(
                            model: ConvolutionalNetwork.fromJson(
                                result['model']! as Map<String, dynamic>)))
                  ],
                  LabNotice(isSom
                      ? 'Cell positions are not class labels. Compare topology as well as error; a low quantization error alone does not prove a useful neighborhood.'
                      : isCnn
                          ? 'Test samples change noise, not bar positions or shape families. Arbitrary drawings can be outside the training distribution. Feature channels use independent contrast normalization.'
                          : 'Test noise is new, but all four clean patterns are familiar. Reconstruction quality here does not establish anomaly detection or compression on real data.'),
                ],
              ],
            )));
  }

  List<Widget> _sampleWidgets(Map<String, Object?> result, bool cnn) {
    final samples = result['samples']! as List<Map<String, Object>>;
    final sample = samples[_sample];
    final prediction = sample['prediction']! as List<double>;
    return [
      LabText('Test sample ${_sample + 1}/${samples.length}'),
      Slider(
          value: _sample.toDouble(),
          semanticFormatterCallback: (v) =>
              tr(context, 'Test sample ${v.round() + 1} of ${samples.length}'),
          min: 0,
          max: (samples.length - 1).toDouble(),
          divisions: samples.length - 1,
          onChanged: (v) => setState(() => _sample = v.round())),
      if (cnn)
        LabText(
            'Target: ${(sample['target']! as List<double>)[0] == 1 ? 'vertical' : 'horizontal'} · predicted probabilities [vertical, horizontal]: ${prediction.map((v) => v.toStringAsFixed(4)).join(', ')}'),
      if (!cnn)
        LabText(
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
        const LabText('Inspect filter channel'),
        Slider(
            value: _channel.toDouble(),
            semanticFormatterCallback: (v) =>
                tr(context, 'Convolution channel ${v.round()}'),
            min: 0,
            max: 3,
            divisions: 3,
            label: tr(context, '$_channel'),
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

import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:neural_engine/neural_engine.dart';
import 'runners/async_demo_recipe.dart';
import 'frame_probe/host_web.dart'
    if (dart.library.io) 'frame_probe/host_native.dart' as host;

void main() {
  runApp(const MaterialApp(home: FrameProbe()));
}

Map<String, Object?> distribution(List<double> input) {
  if (input.isEmpty) {
    return {'samples': 0, 'medianMs': null, 'p95Ms': null, 'maxMs': null};
  }
  final values = List<double>.of(input)..sort();
  return {
    'samples': values.length,
    'medianMs': values[values.length ~/ 2],
    'p95Ms': values[((values.length - 1) * 0.95).ceil()],
    'maxMs': values.last
  };
}

class FrameProbe extends StatefulWidget {
  const FrameProbe({super.key});
  @override
  State<FrameProbe> createState() => _FrameProbeState();
}

class _FrameProbeState extends State<FrameProbe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final _frames = <FrameTiming>[];
  bool _training = false;
  String _status = 'Warming animated interface';
  void _timings(List<FrameTiming> timings) {
    if (_training) _frames.addAll(timings);
  }

  @override
  void initState() {
    super.initState();
    _animation =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    if (!kIsWeb) SchedulerBinding.instance.addTimingsCallback(_timings);
    _run();
  }

  Future<void> _run() async {
    await host.waitForStart();
    await Future<void>.delayed(const Duration(seconds: 2));
    final recipe = AsyncDemoRecipe('CNN');
    final data = recipe.request(recipe.initial, 160).toJson();
    final inputs = data['inputs'] as List;
    final targets = data['targets'] as List;
    data['inputs'] = [for (var i = 0; i < 8; i++) ...inputs];
    data['targets'] = [for (var i = 0; i < 8; i++) ...targets];
    data['batchSize'] = 4;
    final tuned = host.policy == 'budgeted';
    data['batchesPerYield'] = tuned ? 16 : 1;
    data['evaluationSamplesPerYield'] = tuned ? 8 : 32;
    data['maxWorkMicroseconds'] = tuned ? 8000 : null;
    setState(() => _status = 'Training CNN · ${host.policy}');
    final request = AsyncTrainingRequest.fromJson(data);
    _frames.clear();
    _training = true;
    host.startPresentationProbe();
    final clock = Stopwatch()..start();
    final task = AsyncTrainingTask.start(request,
        execution: host.cooperative
            ? TrainingExecution.cooperative
            : TrainingExecution.automatic);
    final result = await task.result;
    clock.stop();
    _training = false;
    final presentation = host.stopPresentationProbe();
    final displays = WidgetsBinding.instance.platformDispatcher.displays;
    final refresh = displays.isEmpty ? null : displays.first.refreshRate;
    final report = <String, Object?>{
      ...host.hostInfo(),
      'releaseMode': kReleaseMode,
      'policy': host.policy,
      'execution': task.execution.name,
      'family': 'CNN',
      'samples': 128,
      'epochs': 160,
      'batchSize': 4,
      'batchesPerYield': data['batchesPerYield'],
      'evaluationSamplesPerYield': data['evaluationSamplesPerYield'],
      'maxWorkMicroseconds': data['maxWorkMicroseconds'],
      'wallUs': clock.elapsedMicroseconds,
      'reportedRefreshRateHz': refresh,
      'frameBuild': distribution(
          _frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()),
      'frameRaster': distribution(
          _frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()),
      'frameTotal': distribution(
          _frames.map((f) => f.totalSpan.inMicroseconds / 1000).toList()),
      'browserRafIntervals': distribution(presentation),
      'checkpointJson': jsonEncode(result.checkpoint.toJson()),
      'measurementNotes':
          'Flutter FrameTiming callbacks delivered during training; browser rAF intervals are presentation opportunities, not raster times. See external Chrome trace. Named CI virtual machine is not a physical phone.'
    };
    setState(() => _status = 'Complete');
    await host.finish(report);
  }

  @override
  void dispose() {
    if (!kIsWeb) SchedulerBinding.instance.removeTimingsCallback(_timings);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Text(_status),
            AnimatedBuilder(
                animation: _animation,
                builder: (context, child) => Transform.rotate(
                    angle: _animation.value * 6.283185307,
                    child: const FlutterLogo(size: 120))),
            const Text('Release-mode frame probe · fixed CPU training recipe'),
          ])));
}

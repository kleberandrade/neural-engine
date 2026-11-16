import '../../layers/spatial/conv2d.dart';
import '../../layers/spatial/max_pool2d.dart';
import 'spatial_stage.dart';
import 'spatial_pass.dart';

List<double> spatialBackward(SpatialPass pass, List<SpatialStage> stages,
    List<double> parameters, List<double> upstream) {
  final result = List<double>.filled(parameters.length, 0);
  for (var l = stages.length - 1; l >= 0; l--) {
    final stage = stages[l];
    final spec = stage.spec;
    final previous = pass.tensors[l].values;
    final inputGradient = List<double>.filled(previous.length, 0);
    if (spec is MaxPool2D) {
      for (var i = 0; i < upstream.length; i++) {
        inputGradient[pass.switches[l][i]] += upstream[i];
      }
    } else if (spec is Conv2D) {
      final delta =
          spec.activation.backward(pass.tensors[l + 1].values, upstream);
      for (var oy = 0; oy < stage.oh; oy++) {
        for (var ox = 0; ox < stage.ow; ox++) {
          for (var oc = 0; oc < stage.oc; oc++) {
            final d = delta[(oy * stage.ow + ox) * stage.oc + oc];
            final base = stage.offset +
                oc * (spec.kernelSize * spec.kernelSize * stage.ic + 1);
            result[base + spec.kernelSize * spec.kernelSize * stage.ic] += d;
            for (var ky = 0; ky < spec.kernelSize; ky++) {
              final iy = oy * spec.stride + ky - stage.padY;
              if (iy < 0 || iy >= stage.ih) continue;
              for (var kx = 0; kx < spec.kernelSize; kx++) {
                final ix = ox * spec.stride + kx - stage.padX;
                if (ix < 0 || ix >= stage.iw) continue;
                for (var ic = 0; ic < stage.ic; ic++) {
                  final p = base + (ky * spec.kernelSize + kx) * stage.ic + ic;
                  final index = (iy * stage.iw + ix) * stage.ic + ic;
                  result[p] += d * previous[index];
                  inputGradient[index] += d * parameters[p];
                }
              }
            }
          }
        }
      }
    }
    upstream = inputGradient;
  }
  if (result.any((v) => !v.isFinite)) {
    throw StateError('Nonfinite spatial gradient.');
  }
  return result;
}

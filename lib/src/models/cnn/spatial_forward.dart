import '../../layers/spatial/conv2d.dart';
import '../../layers/spatial/max_pool2d.dart';
import '../../tensors/image_tensor.dart';
import 'spatial_stage.dart';
import 'spatial_pass.dart';

SpatialPass spatialForward(
    ImageTensor input, List<SpatialStage> stages, List<double> parameters) {
  final tensors = <ImageTensor>[input];
  final switches = <List<int>>[];
  for (final stage in stages) {
    final x = tensors.last.values;
    final output = List<double>.filled(stage.oh * stage.ow * stage.oc, 0);
    final routes = List<int>.filled(output.length, -1);
    final spec = stage.spec;
    for (var oy = 0; oy < stage.oh; oy++) {
      for (var ox = 0; ox < stage.ow; ox++) {
        for (var oc = 0; oc < stage.oc; oc++) {
          final out = (oy * stage.ow + ox) * stage.oc + oc;
          if (spec is Conv2D) {
            final base = stage.offset +
                oc * (spec.kernelSize * spec.kernelSize * stage.ic + 1);
            var sum =
                parameters[base + spec.kernelSize * spec.kernelSize * stage.ic];
            for (var ky = 0; ky < spec.kernelSize; ky++) {
              final iy = oy * spec.stride + ky - stage.padY;
              if (iy < 0 || iy >= stage.ih) continue;
              for (var kx = 0; kx < spec.kernelSize; kx++) {
                final ix = ox * spec.stride + kx - stage.padX;
                if (ix < 0 || ix >= stage.iw) continue;
                for (var ic = 0; ic < stage.ic; ic++) {
                  final p = base + (ky * spec.kernelSize + kx) * stage.ic + ic;
                  sum +=
                      x[(iy * stage.iw + ix) * stage.ic + ic] * parameters[p];
                }
              }
            }
            output[out] = sum;
          } else if (spec is MaxPool2D) {
            var best = double.negativeInfinity;
            for (var ky = 0; ky < spec.poolSize; ky++) {
              for (var kx = 0; kx < spec.poolSize; kx++) {
                final index = ((oy * spec.stride + ky) * stage.iw +
                            ox * spec.stride +
                            kx) *
                        stage.ic +
                    oc;
                if (x[index] > best) {
                  best = x[index];
                  routes[out] = index;
                }
              }
            }
            output[out] = best;
          }
        }
      }
    }
    final activated = spec is Conv2D ? spec.activation.forward(output) : output;
    tensors.add(ImageTensor(
        height: stage.oh,
        width: stage.ow,
        channels: stage.oc,
        values: activated));
    switches.add(routes);
  }
  return SpatialPass(tensors, switches);
}

import '../../tensors/image_tensor.dart';

class SpatialPass {
  final List<ImageTensor> tensors;
  final List<List<int>> switches;
  SpatialPass(this.tensors, this.switches);
}

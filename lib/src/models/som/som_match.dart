/// Best matching unit on a rectangular, non-toroidal SOM grid.
class SomMatch {
  final int row;
  final int column;
  final double distance;
  const SomMatch(this.row, this.column, this.distance);
}

import '../l10n/lab_copy.dart';
import 'package:material_ui/material_ui.dart';

class PlotPanel extends StatelessWidget {
  final String title;
  final CustomPainter painter;
  const PlotPanel({required this.title, required this.painter});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LabText(title),
        const SizedBox(height: 12),
        AspectRatio(aspectRatio: 1.25, child: CustomPaint(painter: painter)),
      ]);
}

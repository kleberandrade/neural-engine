import '../l10n/lab_copy.dart';
import 'package:material_ui/material_ui.dart';

class PixelGrid extends StatelessWidget {
  final String title;
  final List<double> values;
  final int columns;
  const PixelGrid({
    required this.title,
    required this.values,
    required this.columns,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 210,
      child: Column(children: [
        LabText(title),
        const SizedBox(height: 8),
        GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            children: [
              for (var i = 0; i < values.length; i++)
                Semantics(
                    label: tr(context,
                        '$title row ${i ~/ columns + 1}, column ${i % columns + 1}: ${values[i].toStringAsFixed(3)}'),
                    child: Tooltip(
                        message: values[i].toStringAsFixed(3),
                        child: ColoredBox(
                            color: Color.lerp(Colors.black, Colors.cyanAccent,
                                values[i].clamp(0.0, 1.0))!))),
            ]),
      ]));
}

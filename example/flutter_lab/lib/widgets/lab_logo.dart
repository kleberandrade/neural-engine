import 'package:material_ui/material_ui.dart';
import '../l10n/lab_copy.dart';

/// Original N-shaped neural graph, shared with the SVG brand and web favicon.
class LabLogo extends StatelessWidget {
  final double size;
  const LabLogo({super.key, this.size = 42});
  @override
  Widget build(BuildContext context) => Semantics(
      image: true,
      label: tr(context, 'Neural Engine logo'),
      child:
          CustomPaint(size: Size.square(size), painter: const _LogoPainter()));
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 64, 64), const Radius.circular(16)),
        Paint()..color = const Color(0xFF203A40));
    final stroke = Paint()
      ..color = const Color(0xFF8DE0CC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
        Path()
          ..moveTo(17, 47)
          ..lineTo(17, 17)
          ..lineTo(47, 47)
          ..lineTo(47, 17),
        stroke);
    canvas.drawPath(
        Path()
          ..moveTo(17, 32)
          ..lineTo(32, 32)
          ..lineTo(47, 32),
        stroke
          ..color = const Color(0xFFAFBBFF)
          ..strokeWidth = 1.5);
    for (final point in [
      const Offset(17, 17),
      const Offset(17, 47),
      const Offset(47, 17),
      const Offset(47, 47)
    ]) {
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFF8DE0CC));
    }
    canvas.drawCircle(
        const Offset(32, 32), 5, Paint()..color = const Color(0xFFAFBBFF));
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

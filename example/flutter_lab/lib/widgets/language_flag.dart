import 'package:material_ui/material_ui.dart';
import '../l10n/lab_copy.dart';

/// Locally drawn, circular national flags; no emoji, fonts or network assets.
class LanguageFlag extends StatelessWidget {
  final LabLanguage language;
  const LanguageFlag(this.language, {super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: CustomPaint(
          size: const Size.square(30), painter: _FlagPainter(language)));
}

class _FlagPainter extends CustomPainter {
  final LabLanguage language;
  const _FlagPainter(this.language);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 32, 32)));
    if (language == LabLanguage.portuguese) {
      canvas.drawColor(const Color(0xFF009B3A), BlendMode.srcOver);
      canvas.drawPath(
          Path()
            ..moveTo(16, 5)
            ..lineTo(30, 16)
            ..lineTo(16, 27)
            ..lineTo(2, 16)
            ..close(),
          Paint()..color = const Color(0xFFFFDF00));
      canvas.drawCircle(
          const Offset(16, 16), 7, Paint()..color = const Color(0xFF002776));
      canvas.drawPath(
          Path()
            ..moveTo(9.4, 14)
            ..quadraticBezierTo(17, 12, 22.5, 18),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
      for (final point in [
        const Offset(12, 18),
        const Offset(16, 19),
        const Offset(19, 20),
        const Offset(15, 22),
        const Offset(20, 16)
      ]) {
        canvas.drawCircle(point, .45, Paint()..color = Colors.white);
      }
    } else {
      canvas.drawColor(const Color(0xFF012169), BlendMode.srcOver);
      for (final line in [
        (const Offset(0, 0), const Offset(32, 32)),
        (const Offset(0, 32), const Offset(32, 0))
      ]) {
        canvas.drawLine(
            line.$1,
            line.$2,
            Paint()
              ..color = Colors.white
              ..strokeWidth = 7);
        canvas.drawLine(
            line.$1,
            line.$2,
            Paint()
              ..color = const Color(0xFFC8102E)
              ..strokeWidth = 2.5);
      }
      canvas.drawRect(
          const Rect.fromLTWH(10.5, 0, 11, 32), Paint()..color = Colors.white);
      canvas.drawRect(
          const Rect.fromLTWH(0, 10.5, 32, 11), Paint()..color = Colors.white);
      canvas.drawRect(const Rect.fromLTWH(13, 0, 6, 32),
          Paint()..color = const Color(0xFFC8102E));
      canvas.drawRect(const Rect.fromLTWH(0, 13, 32, 6),
          Paint()..color = const Color(0xFFC8102E));
    }
    canvas.restore();
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - .5,
        Paint()
          ..color = const Color(0xFF96A7BC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8);
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.language != language;
}

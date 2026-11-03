import 'package:flutter/material.dart';

/// The CarWash logo "night shine": a sky-blue car with sparkles on night blue, in a rounded square,
/// matching the launcher icon.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2545), Color(0xFF13416B)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

/// Draws the logo in a 108-unit square, like the launcher icon's vector, scaled to the widget.
class _LogoPainter extends CustomPainter {
  static const _sky = Color(0xFF4FC3F7);
  static const _night = Color(0xFF0B2545);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108);

    final sky = Paint()..color = _sky;
    final white = Paint()..color = Colors.white;

    final body = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(24, 66)
      ..lineTo(30, 55)
      ..quadraticBezierTo(33, 50, 39, 49)
      ..lineTo(58, 47)
      ..quadraticBezierTo(66, 46.5, 72, 52)
      ..lineTo(78, 58)
      ..quadraticBezierTo(85, 59, 86, 64)
      ..lineTo(86, 70)
      ..quadraticBezierTo(86, 72.5, 83.5, 72.5)
      ..lineTo(24.5, 72.5)
      ..quadraticBezierTo(22, 72.5, 22, 70)
      ..lineTo(22, 68)
      ..quadraticBezierTo(22, 66.3, 24, 66)
      ..close()
      ..moveTo(33, 64)
      ..lineTo(37, 56)
      ..quadraticBezierTo(38.3, 53.6, 41, 53.4)
      ..lineTo(52, 52.6)
      ..lineTo(52, 64)
      ..close()
      ..moveTo(55.5, 64)
      ..lineTo(55.5, 52.4)
      ..lineTo(60, 52.2)
      ..quadraticBezierTo(65, 52, 68.5, 55.6)
      ..lineTo(72.5, 64)
      ..close();
    canvas.drawPath(body, sky);

    for (final x in [36.0, 72.0]) {
      canvas.drawCircle(Offset(x, 72.5), 6, sky);
      canvas.drawCircle(Offset(x, 72.5), 2.4, Paint()..color = _night);
    }

    canvas.drawPath(_sparkle(74, 31, 9, 8), white);
    canvas.drawPath(_sparkle(50, 33, 5, 5), white);
    canvas.drawPath(_sparkle(30, 37, 3, 3), Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  /// A four-pointed sparkle centred on ([x], [y]), [height] above and below and [width] to each side.
  Path _sparkle(double x, double y, double height, double width) {
    final bend = width / 8;
    return Path()
      ..moveTo(x, y - height)
      ..quadraticBezierTo(x + bend, y - bend, x + width, y)
      ..quadraticBezierTo(x + bend, y + bend, x, y + height)
      ..quadraticBezierTo(x - bend, y + bend, x - width, y)
      ..quadraticBezierTo(x - bend, y - bend, x, y - height)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

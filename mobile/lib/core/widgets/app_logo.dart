import 'package:flutter/material.dart';

/// The CarWash logo: a car under a water drop and bubbles, white on the brand colour in a rounded square,
/// matching the launcher icon.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFF29B6F6), borderRadius: BorderRadius.circular(size * 0.28)),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

/// Draws the logo in a 108-unit square, like the launcher icon's vector, scaled to the widget.
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 108;
    canvas.scale(scale);

    final white = Paint()..color = Colors.white;
    final bubbles = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final hubs = Paint()..color = const Color(0xFF0288D1);

    final drop = Path()
      ..moveTo(54, 24)
      ..cubicTo(54, 24, 46.5, 33, 46.5, 37.5)
      ..arcToPoint(const Offset(61.5, 37.5), radius: const Radius.circular(7.5), clockwise: false)
      ..cubicTo(61.5, 33, 54, 24, 54, 24)
      ..close();
    canvas.drawPath(drop, white);
    canvas.drawCircle(const Offset(40, 40), 3, bubbles);
    canvas.drawCircle(const Offset(68, 37), 2.5, bubbles);

    final body = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(31, 62)
      ..lineTo(35, 53)
      ..quadraticBezierTo(37, 49, 42, 49)
      ..lineTo(66, 49)
      ..quadraticBezierTo(71, 49, 73, 53)
      ..lineTo(77, 62)
      ..quadraticBezierTo(81, 62.5, 81, 66)
      ..lineTo(81, 72)
      ..quadraticBezierTo(81, 74, 79, 74)
      ..lineTo(29, 74)
      ..quadraticBezierTo(27, 74, 27, 72)
      ..lineTo(27, 66)
      ..quadraticBezierTo(27, 62.5, 31, 62)
      ..close()
      ..moveTo(39, 61)
      ..lineTo(41.5, 55)
      ..quadraticBezierTo(42.5, 53, 44.5, 53)
      ..lineTo(52.5, 53)
      ..lineTo(52.5, 61)
      ..close()
      ..moveTo(55.5, 61)
      ..lineTo(55.5, 53)
      ..lineTo(63.5, 53)
      ..quadraticBezierTo(65.5, 53, 66.5, 55)
      ..lineTo(69, 61)
      ..close();
    canvas.drawPath(body, white);

    for (final x in [39.0, 69.0]) {
      canvas.drawCircle(Offset(x, 74), 5.5, white);
      canvas.drawCircle(Offset(x, 74), 2.2, hubs);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 180});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/autodoc_logo.png',
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _FallbackBrandLogo(width: width),
    );
  }
}

class _FallbackBrandLogo extends StatelessWidget {
  const _FallbackBrandLogo({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blue = theme.colorScheme.primary;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: width * 0.42,
            child: CustomPaint(painter: _AutoDocMarkPainter(primary: blue)),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
              children: [
                TextSpan(
                  text: 'AUTO',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                TextSpan(
                  text: 'DOC',
                  style: TextStyle(color: blue),
                ),
                TextSpan(
                  text: ' AI',
                  style: TextStyle(color: blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoDocMarkPainter extends CustomPainter {
  const _AutoDocMarkPainter({required this.primary});

  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 220;
    canvas.save();
    canvas.scale(scale, scale);

    final carPaint = Paint()
      ..color = const Color(0xff263746)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final car = Path()
      ..moveTo(12, 102)
      ..quadraticBezierTo(19, 73, 56, 67)
      ..quadraticBezierTo(86, 29, 140, 36)
      ..quadraticBezierTo(166, 39, 190, 68)
      ..lineTo(207, 74)
      ..quadraticBezierTo(216, 78, 216, 96)
      ..lineTo(211, 108)
      ..lineTo(16, 108)
      ..close();
    canvas.drawPath(car, carPaint);
    canvas.drawPath(car, outlinePaint);

    final window = Path()
      ..moveTo(70, 64)
      ..quadraticBezierTo(88, 43, 117, 43)
      ..lineTo(139, 44)
      ..lineTo(122, 66)
      ..close();
    canvas.drawPath(window, Paint()..color = Colors.white);

    canvas.drawCircle(const Offset(51, 105), 14, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(51, 105), 7, Paint()..color = primary);
    canvas.drawCircle(
      const Offset(166, 105),
      14,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(166, 105), 7, Paint()..color = primary);

    final crossFill = Paint()..color = Colors.white;
    final crossOutline = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final cross = Path()
      ..moveTo(171, 12)
      ..lineTo(197, 12)
      ..lineTo(197, 34)
      ..lineTo(219, 34)
      ..lineTo(219, 60)
      ..lineTo(197, 60)
      ..lineTo(197, 82)
      ..lineTo(171, 82)
      ..lineTo(171, 60)
      ..lineTo(149, 60)
      ..lineTo(149, 34)
      ..lineTo(171, 34)
      ..close();
    canvas.drawPath(cross, crossFill);
    canvas.drawPath(cross, crossOutline);

    final nodePaint = Paint()..color = primary;
    canvas.drawCircle(const Offset(182, 28), 4, nodePaint);
    canvas.drawCircle(const Offset(207, 47), 4, nodePaint);
    canvas.drawCircle(const Offset(182, 68), 4, nodePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AutoDocMarkPainter oldDelegate) {
    return oldDelegate.primary != primary;
  }
}

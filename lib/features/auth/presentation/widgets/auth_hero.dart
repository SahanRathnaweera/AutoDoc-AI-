import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/brand_logo.dart';

/// Animated header for the login and sign-up pages: a top-down car inside the
/// capture rings, with a scanner line sweeping over it.
class AuthHero extends StatefulWidget {
  const AuthHero({
    super.key,
    required this.height,
    this.compact = false,
    this.onBack,
    this.child,
  });

  final double height;

  /// Compact mode moves the artwork to the right to make room for a title.
  final bool compact;

  final VoidCallback? onBack;

  /// Optional title shown at the bottom-left of the header.
  final Widget? child;

  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: widget.height + top,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) => CustomPaint(
                painter: _HeroPainter(_c.value, widget.compact),
              ),
            ),
          ),
          Positioned(
            top: top + 10,
            left: 8,
            child: Row(
              children: [
                if (widget.onBack != null)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  )
                else
                  const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const BrandLogo(width: 96),
                ),
              ],
            ),
          ),
          if (widget.child != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: widget.child!,
            ),
        ],
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.t, this.compact);

  final double t;
  final bool compact;

  static const _accent = Color(0xFF3B9CFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F33), Color(0xFF0F3558)],
        ).createShader(rect),
    );

    final h = size.height;
    final c = compact
        ? Offset(size.width * 0.80, h * 0.52)
        : Offset(size.width * 0.5, h * 0.56);
    final r = compact ? h * 0.44 : h * 0.38;

    // Concentric rings.
    for (final f in [1.0, 0.72, 0.46]) {
      canvas.drawCircle(
        c,
        r * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withAlpha(f == 1.0 ? 38 : 22),
      );
    }

    // Car, front at the top.
    final bw = r * 0.5;
    final bh = r * 1.1;

    final wheel = Paint()..color = const Color(0xFF2B4A63);
    for (final dx in [-1.0, 1.0]) {
      for (final dy in [-0.3, 0.32]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c + Offset(dx * bw * 0.5, dy * bh),
              width: bw * 0.14,
              height: bh * 0.2,
            ),
            const Radius.circular(4),
          ),
          wheel,
        );
      }
    }

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: bw, height: bh),
      Radius.circular(bw * 0.38),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF1B3A55));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(60),
    );

    final glass = Paint()..color = Colors.white.withAlpha(46);
    final roof = Paint()..color = Colors.white.withAlpha(18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, -bh * 0.2),
          width: bw * 0.74,
          height: bh * 0.17,
        ),
        const Radius.circular(8),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, bh * 0.04),
          width: bw * 0.7,
          height: bh * 0.24,
        ),
        const Radius.circular(8),
      ),
      roof,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, bh * 0.27),
          width: bw * 0.7,
          height: bh * 0.12,
        ),
        const Radius.circular(8),
      ),
      glass,
    );

    // Scanner line sweeping over the car (loops every 4 seconds).
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    final phase = (t * 6) % 1.0;
    final k = 0.5 - 0.5 * math.cos(2 * math.pi * phase);
    final y = c.dy - bh / 2 - 10 + k * (bh + 20);
    final band = Rect.fromLTWH(c.dx - r, y - 26, r * 2, 52);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withAlpha(0),
            _accent.withAlpha(70),
            _accent.withAlpha(0),
          ],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(c.dx - r, y),
      Offset(c.dx + r, y),
      Paint()
        ..color = _accent
        ..strokeWidth = 1.6,
    );
    canvas.restore();

    // Eight capture points slowly orbiting the outer ring.
    final spin = t * 2 * math.pi;
    for (var i = 0; i < 8; i++) {
      final a = spin + i * math.pi / 4;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        canvas.drawCircle(
          p,
          12,
          Paint()
            ..color = _accent.withAlpha(80)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawCircle(p, 6, Paint()..color = _accent);
      } else {
        canvas.drawCircle(p, 4, Paint()..color = Colors.white.withAlpha(90));
      }
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.t != t;
}
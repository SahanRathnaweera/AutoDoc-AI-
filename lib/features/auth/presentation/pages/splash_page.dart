import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/brand_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.isSignedIn});

  final bool Function() isSignedIn;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _ring;
  late final Animation<double> _logo;
  late final Animation<double> _tagline;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _logo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
    );
    _ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1, curve: Curves.easeInOutCubic),
    );
    _tagline = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
    );

    // Same logic as before: signed-in users go to the dashboard.
    _navigationTimer = Timer(const Duration(milliseconds: 2700), () {
      if (mounted) context.go(widget.isSignedIn() ? '/dashboard' : '/auth');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (context, child) => CustomPaint(
                      size: const Size(300, 300),
                      painter: _RingPainter(_ring.value, p),
                    ),
                  ),
                  FadeTransition(
                    opacity: _logo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        // The logo always sits on white so it stays readable.
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const BrandLogo(width: 170),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _tagline,
              child: Text(
                'Guided. Diagnostic. Trusted.',
                style: text.bodyLarge?.copyWith(
                  color: p.muted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 8-point capture ring from the camera stencil, drawn once while loading.
class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.p);

  final double t;
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 14;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = p.text.withAlpha(60),
    );

    for (var k = 0; k < 8; k++) {
      final reveal = (t * 8 - k).clamp(0.0, 1.0);
      if (reveal == 0) continue;
      final angle = -math.pi / 2 + k * math.pi / 4;
      final pt = c + Offset(math.cos(angle), math.sin(angle)) * r;

      canvas.drawCircle(pt, 10 * reveal, Paint()..color = p.surface);
      canvas.drawCircle(
        pt,
        10 * reveal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = k == 0 ? p.accent : p.line,
      );
      if (k == 0) {
        canvas.drawCircle(pt, 4.5 * reveal, Paint()..color = p.accent);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.p != p;
}
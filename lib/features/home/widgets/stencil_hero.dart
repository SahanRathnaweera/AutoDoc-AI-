import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The one memorable element: a top-down car inside the 8-point capture ring
/// used by the guided 360° camera. The ring draws itself once on load.
class StencilHero extends StatefulWidget {
  const StencilHero({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<StencilHero> createState() => _StencilHeroState();
}

class _StencilHeroState extends State<StencilHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, child) => CustomPaint(
                painter: _StencilPainter(_t.value, p, dark),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Walk around the car',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '8 photos, starting at the front bumper',
            style: text.bodyMedium?.copyWith(color: p.muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: widget.onStart,
              style: FilledButton.styleFrom(
                backgroundColor: p.strong,
                foregroundColor: p.onStrong,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Start inspection',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StencilPainter extends CustomPainter {
  _StencilPainter(this.t, this.p, this.dark);

  final double t;
  final AppPalette p;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 16;

    // Capture ring, drawn progressively.
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

    // Car, front at the top.
    final bw = r * 0.56;
    final bh = r * 1.28;

    final wheel = Paint()..color = p.muted;
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: bw, height: bh),
        Radius.circular(bw * 0.38),
      ),
      Paint()..color = dark ? const Color(0xFF3A5A6C) : AppColors.ink,
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

    // Eight capture points, revealed as the ring passes them.
    for (var k = 0; k < 8; k++) {
      final angle = -math.pi / 2 + k * math.pi / 4;
      final reveal = (t * 8 - k).clamp(0.0, 1.0);
      if (reveal == 0) continue;

      final pt = c + Offset(math.cos(angle), math.sin(angle)) * r;
      canvas.drawCircle(pt, 11 * reveal, Paint()..color = p.surface);
      canvas.drawCircle(
        pt,
        11 * reveal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = k == 0 ? p.accent : p.line,
      );
      if (k == 0) {
        canvas.drawCircle(pt, 5 * reveal, Paint()..color = p.accent);
      }
    }
  }

  @override
  bool shouldRepaint(_StencilPainter old) =>
      old.t != t || old.dark != dark;
}
// Komponen shared — latar aplikasi "Sakura Dusk".
//
// Satu Stack dekoratif untuk seluruh layar: gradien kertas senja, dua glow
// radial lembut, dan tujuh blossom bergaris bezier. Semua statis (tanpa
// AnimationController) dan dikecualikan dari semantics.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/app_effects.dart';

/// Latar dekoratif bersama untuk semua layar.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.petals = 7, this.intensity = 1});

  /// Jumlah blossom yang digambar.
  final int petals;

  /// Pengali alpha glow & blossom (0–1).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = intensity.clamp(0.0, 1.0);

    return Semantics(
      label: null,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.background(context),
                ),
              ),
              Positioned(
                top: -120,
                left: -80,
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          scheme.primary.withValues(
                            alpha: (isDark ? 0.14 : 0.10) * amount,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -160,
                right: -100,
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          scheme.secondary.withValues(
                            alpha: (isDark ? 0.13 : 0.09) * amount,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CustomPaint(
                painter: _SakuraPetalsPainter(
                  petals: petals,
                  color: isDark
                      ? scheme.primary.withValues(alpha: 0.10 * amount)
                      : scheme.primary.withValues(alpha: 0.08 * amount),
                ),
                size: Size.infinite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SakuraPetalsPainter extends CustomPainter {
  _SakuraPetalsPainter({required this.petals, required this.color});

  final int petals;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7); // seed tetap → pola stabil antar rebuild.
    final paint = Paint()..color = color;

    for (int i = 0; i < petals; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final s = 10 + rng.nextDouble() * 12; // ukuran blossom 10–22
      final rot = rng.nextDouble() * math.pi * 2;
      _drawBlossom(canvas, paint, Offset(x, y), s, rot);
    }
  }

  void _drawBlossom(Canvas canvas, Paint paint, Offset center, double s, double rot) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);
    final petal = Path()
      ..moveTo(0, 0)
      ..cubicTo(0.18 * s, -0.26 * s, 0.34 * s, -0.20 * s, 0.46 * s, 0)
      ..cubicTo(0.34 * s, 0.20 * s, 0.18 * s, 0.26 * s, 0, 0)
      ..close();
    for (int k = 0; k < 5; k++) {
      canvas.save();
      canvas.rotate(k * 2 * math.pi / 5);
      canvas.drawPath(petal, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SakuraPetalsPainter oldDelegate) =>
      oldDelegate.petals != petals || oldDelegate.color != color;
}

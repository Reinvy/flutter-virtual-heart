// Komponen shared — latar kelopak sakura dekoratif.
//
// Partikel kelopak digambar dengan CustomPainter (tanpa aset raster).
// Menghormati `MediaQuery.disableAnimations` (statis) dan dikecualikan
// dari semantics karena murni dekoratif.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Hamburan kelopak sakura di belakang konten layar.
///
/// Gunakan sebagai background: `Stack(children: [SakuraBackground(), ...])`
/// atau `SizedBox.expand(child: SakuraBackground())`.
class SakuraBackground extends StatelessWidget {
  const SakuraBackground({super.key, this.petals = 9, this.opacity = 0.5});

  /// Jumlah kelopak yang digambar (8–14 ideal).
  final int petals;

  /// Opacity keseluruhan lapisan kelopak.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: null,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SakuraPetalsPainter(
            petals: petals,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primaryDark.withValues(alpha: 0.10 * opacity)
                : AppColors.primary.withValues(alpha: 0.07 * opacity),
            motionOk: !MediaQuery.disableAnimationsOf(context),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SakuraPetalsPainter extends CustomPainter {
  _SakuraPetalsPainter({required this.petals, required this.color, required this.motionOk});

  final int petals;
  final Color color;
  final bool motionOk;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42); // seed tetap → pola stabil antar rebuild.
    final paint = Paint()..color = color;

    for (int i = 0; i < petals; i++) {
      final x = rng.nextDouble() * size.width;
      final y = motionOk ? rng.nextDouble() * size.height : (i / petals) * size.height;
      final s = 6 + rng.nextDouble() * 8; // ukuran kelopak 6–14
      final rot = rng.nextDouble() * math.pi * 2;
      _drawPetal(canvas, paint, x, y, s, rot);
    }
  }

  void _drawPetal(Canvas canvas, Paint paint, double x, double y, double s, double rot) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);
    // Kelopak sederhana: 5 lingkaran kecil di sekitar pusat.
    for (int k = 0; k < 5; k++) {
      final angle = k * 2 * math.pi / 5;
      final dx = math.cos(angle) * s * 0.55;
      final dy = math.sin(angle) * s * 0.55;
      canvas.drawCircle(Offset(dx, dy), s * 0.42, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SakuraPetalsPainter oldDelegate) =>
      oldDelegate.petals != petals ||
      oldDelegate.color != color ||
      oldDelegate.motionOk != motionOk;
}

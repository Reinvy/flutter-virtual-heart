// Komponen shared — ResonanceMark (emblem orbital dual-ring).
//
// Marka visual aplikasi: dua cincin orbital eksentrik 1.25px dengan titik/ikon
// pusat. Animasi rotasi halus hanya berjalan saat motion diizinkan.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_durations.dart';

class ResonanceMark extends StatefulWidget {
  const ResonanceMark({
    super.key,
    this.size = 96,
    this.icon,
    this.animate = false,
    this.subtleRing = true,
  });

  final double size;
  final IconData? icon;
  final bool animate;
  final bool subtleRing;

  @override
  State<ResonanceMark> createState() => _ResonanceMarkState();
}

class _ResonanceMarkState extends State<ResonanceMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.durationOrbital,
  );

  bool _motionOk = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(ResonanceMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final ok = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (ok == _motionOk) return;
    _motionOk = ok;
    if (ok) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppColors.paletteOf(context);
    final size = widget.size;

    final Widget rings = CustomPaint(
      size: Size.square(size),
      painter: _ResonancePainter(
        primary: scheme.primary,
        secondary: widget.subtleRing
            ? palette.secondary.withValues(alpha: 0.72)
            : palette.secondary,
        surface: scheme.surface,
        outline: scheme.outlineVariant,
        hasIcon: widget.icon != null,
      ),
    );

    Widget content = Stack(
      alignment: Alignment.center,
      children: [
        if (_motionOk)
          RotationTransition(turns: _controller, child: rings)
        else
          rings,
        if (widget.icon != null)
          Container(
            width: size * 0.44,
            height: size * 0.44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
              border: Border.all(color: scheme.outlineVariant, width: 1),
            ),
            child: Icon(
              widget.icon,
              size: math.max(14, size * 0.22),
              color: palette.primaryDeep,
            ),
          )
        else
          Container(
            width: math.max(4, size * 0.08),
            height: math.max(4, size * 0.08),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
          ),
      ],
    );

    return ExcludeSemantics(
      child: SizedBox.square(dimension: size, child: content),
    );
  }
}

class _ResonancePainter extends CustomPainter {
  _ResonancePainter({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.outline,
    required this.hasIcon,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color outline;
  final bool hasIcon;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = math.max(1.1, math.min(1.8, s * 0.018));

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = primary;

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = secondary;

    // Cincin luar sedikit bergeser ke kiri-atas
    final outerOffset = Offset(center.dx - s * 0.04, center.dy - s * 0.03);
    canvas.drawCircle(outerOffset, s * 0.39, outerPaint);

    // Cincin kedua sedikit bergeser ke kanan-bawah membentuk silang orbital
    final innerOffset = Offset(center.dx + s * 0.05, center.dy + s * 0.04);
    canvas.drawCircle(innerOffset, s * 0.31, innerPaint);

    if (!hasIcon) {
      final coreRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline;
      canvas.drawCircle(center, s * 0.16, coreRing);
    }
  }

  @override
  bool shouldRepaint(_ResonancePainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.surface != surface ||
      oldDelegate.outline != outline ||
      oldDelegate.hasIcon != hasIcon;
}

// Komponen shared — BloomMark (cincin kelopak + ikon).
//
// Marka visual aplikasi: lima kelopak bezier berpusat pada ikon. Animasi
// napas hanya berjalan saat motion diizinkan; selain itu marka statis.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_effects.dart';

class BloomMark extends StatefulWidget {
  const BloomMark({
    super.key,
    this.size = 96,
    this.icon,
    this.animate = false,
    this.glow = true,
  });

  final double size;
  final IconData? icon;
  final bool animate;
  final bool glow;

  @override
  State<BloomMark> createState() => _BloomMarkState();
}

class _BloomMarkState extends State<BloomMark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.durationBreath,
  );

  bool _motionOk = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(BloomMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final ok = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (ok == _motionOk) return;
    _motionOk = ok;
    if (ok) {
      _controller.repeat(reverse: true);
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
    final size = widget.size;

    Widget mark = CustomPaint(
      size: Size.square(size),
      painter: _BloomPainter(
        primary: scheme.primary,
        secondary: scheme.secondary,
        surface: scheme.surface,
        center: scheme.primaryContainer,
        icon: widget.icon ?? Icons.favorite_rounded,
        iconColor: AppColors.primaryDeepFor(context),
      ),
    );

    if (widget.glow) {
      mark = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(context, scheme.primary),
        ),
        child: mark,
      );
    }

    if (_motionOk) {
      mark = ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.035).animate(
          CurvedAnimation(parent: _controller, curve: AppDurations.curveEmotive),
        ),
        child: mark,
      );
    }

    return ExcludeSemantics(child: SizedBox.square(dimension: size, child: mark));
  }
}

class _BloomPainter extends CustomPainter {
  _BloomPainter({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.center,
    required this.icon,
    required this.iconColor,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color center;
  final IconData icon;
  final Color iconColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    final origin = Offset(size.width / 2, size.height / 2);

    final petal = Path()
      ..moveTo(0, 0)
      ..cubicTo(0.18 * s, -0.26 * s, 0.34 * s, -0.20 * s, 0.46 * s, 0)
      ..cubicTo(0.34 * s, 0.20 * s, 0.18 * s, 0.26 * s, 0, 0)
      ..close();

    final petalPaint = Paint()
      ..shader = LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: origin, radius: s / 2));

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * 2 * math.pi / 5);
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }
    canvas.restore();

    canvas.drawCircle(origin, 0.17 * s, Paint()..color = surface);
    canvas.drawCircle(origin, 0.13 * s, Paint()..color = center);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 0.28 * s,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      origin - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BloomPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.surface != surface ||
      oldDelegate.center != center ||
      oldDelegate.icon != icon ||
      oldDelegate.iconColor != iconColor;
}

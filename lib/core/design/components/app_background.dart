// Komponen shared — latar aplikasi datar dengan sheen sudut minimal.
import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';

/// Latar kanvas bersama untuk semua layar sesuai tema aktif.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: palette.background),
              Positioned(
                top: -140,
                right: -100,
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

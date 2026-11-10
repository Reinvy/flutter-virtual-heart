// Komponen shared — IconButton dengan target sentuh minimum 48×48.
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size = AppSizes.iconMd,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      tooltip: tooltip,
      iconSize: size,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: color ?? scheme.onSurfaceVariant,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
        minimumSize: const Size.square(AppSizes.touchTarget),
        shape: const CircleBorder(),
      ),
    );
  }
}

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
    this.bordered = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool bordered;

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
        side: bordered
            ? BorderSide(color: scheme.outlineVariant, width: 1)
            : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );
  }
}

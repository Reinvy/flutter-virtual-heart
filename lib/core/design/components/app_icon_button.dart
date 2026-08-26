// Komponen shared — IconButton dengan target sentuh minimum 48×48.
import 'package:flutter/material.dart';

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
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size, color: color ?? scheme.onSurfaceVariant),
      constraints: const BoxConstraints(
        minWidth: AppSizes.touchTarget,
        minHeight: AppSizes.touchTarget,
      ),
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      iconSize: size,
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

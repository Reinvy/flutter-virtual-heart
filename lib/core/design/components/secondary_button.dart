// Komponen shared — SecondaryButton & GhostButton (docs/DESIGN.md §3.1)
import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

/// Tombol sekunder: outline tonal, tinggi 52.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.secondary,
        side: BorderSide(color: scheme.secondary),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceLg, vertical: AppSizes.spaceMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconMd, color: scheme.secondary),
            const SizedBox(width: AppSizes.spaceXs),
          ],
          Text(label, style: AppTextStyles.button(color: scheme.secondary)),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Tombol tersier: tanpa fill, teks primary.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective = color ?? Theme.of(context).colorScheme.primary;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: effective),
      child: Text(label, style: AppTextStyles.button(color: effective)),
    );
  }
}

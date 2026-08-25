// Komponen shared — SecondaryButton & GhostButton (docs/DESIGN.md §3.1)
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

/// Tombol sekunder: outline/tonal [AppColors.secondary], tinggi 52.
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
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        side: const BorderSide(color: AppColors.secondary),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceLg, vertical: AppSizes.spaceMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconMd, color: AppColors.secondary),
            const SizedBox(width: AppSizes.spaceXs),
          ],
          Text(label, style: AppTextStyles.button(color: AppColors.secondary)),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Tombol tersier: tanpa fill, teks [AppColors.primary].
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
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color ?? AppColors.primary),
      child: Text(label, style: AppTextStyles.button(color: color ?? AppColors.primary)),
    );
  }
}

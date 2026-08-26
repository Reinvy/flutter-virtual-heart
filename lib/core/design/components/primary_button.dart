// Komponen shared — PrimaryButton (docs/DESIGN.md §3.1)
//
// Fill primary, radius pill (konsisten dengan tema), tinggi 52, label button.
// Warna via ColorScheme agar konsisten di light & dark.
import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

/// Tombol aksi utama: fill primary, pill, tinggi 52.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconMd, color: scheme.onPrimary),
                const SizedBox(width: AppSizes.spaceXs),
              ],
              Text(label, style: AppTextStyles.button(color: scheme.onPrimary)),
            ],
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceLg, vertical: AppSizes.spaceMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      ),
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

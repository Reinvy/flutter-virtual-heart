// Komponen shared — SecondaryButton & GhostButton (docs/DESIGN.md §3.1)
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

/// Tombol sekunder: tonal outline, tinggi 52.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;
    final contentColor = enabled
        ? scheme.secondary
        : scheme.onSurface.withValues(alpha: 0.38);
    final radius = BorderRadius.circular(AppSizes.radiusFull);

    Widget labelText = Text(
      label,
      style: AppTextStyles.button(color: contentColor),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    if (expand) labelText = Flexible(child: labelText);

    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: enabled
            ? scheme.secondary.withValues(alpha: isDark ? 0.12 : 0.06)
            : Colors.transparent,
        foregroundColor: contentColor,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: contentColor,
        side: BorderSide(
          color: enabled
              ? scheme.secondary.withValues(alpha: 0.35)
              : scheme.outlineVariant,
          width: 1,
        ),
        elevation: 0,
        minimumSize: const Size.fromHeight(AppSizes.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppSizes.spaceSm),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: AppTextStyles.button(color: contentColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: contentColor),
            const SizedBox(width: AppSizes.spaceXs),
          ],
          labelText,
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
    final scheme = Theme.of(context).colorScheme;
    final effective = onPressed == null
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (color ?? scheme.primary);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: effective),
      child: Text(label, style: AppTextStyles.button(color: effective)),
    );
  }
}

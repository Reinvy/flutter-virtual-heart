// Komponen shared — PrimaryButton (docs/DESIGN.md §3.1)
//
// Fill solid `scheme.primary`, radiusControl (12), tinggi minimal 50,
// tanpa gradien atau shadow. State disabled memakai fill netral redup;
// state loading mempertahankan fill aktif dengan spinner.
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

/// Tombol aksi utama: solid editorial, tinggi minimal 50.
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
    final active = loading || onPressed != null;
    final foreground = active
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.38);
    final radius = BorderRadius.circular(AppSizes.radiusControl);

    Widget labelText = Text(
      label,
      style: AppTextStyles.button(color: foreground),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    if (expand) labelText = Flexible(child: labelText);

    final content = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: AppSizes.spaceXs),
              ],
              labelText,
            ],
          );

    final button = Semantics(
      button: true,
      enabled: onPressed != null && !loading,
      child: Material(
        color: active
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: loading ? null : onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.controlHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: AppSizes.spaceSm,
              ),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// Komponen shared — empty state seragam (docs/DESIGN.md §3.7).
import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';
import 'resonance_mark.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
    this.action,
    this.mark = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? iconColor;
  final Widget? action;

  /// Tampilkan [ResonanceMark] sebagai ilustrasi, bukan bingkai ikon statis.
  final bool mark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = iconColor ?? scheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mark)
                ResonanceMark(
                  size: AppSizes.avatarLg,
                  icon: icon,
                  animate: true,
                )
              else
                Container(
                  width: AppSizes.avatarLg,
                  height: AppSizes.avatarLg,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    color: scheme.surface,
                    border: Border.all(color: scheme.outlineVariant, width: 1),
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
              const SizedBox(height: AppSizes.spaceLg),
              Text(
                title,
                style: AppTextStyles.headingLarge(
                  context,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spaceXs),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textSecondaryFor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSizes.spaceLg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

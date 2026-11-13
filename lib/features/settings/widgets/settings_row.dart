// Settings — satu baris seragam (ikon, judul, subjudul, trailing).
import 'package:material_ui/material_ui.dart';

import '../../../core/design/components/app_icon_badge.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.selected = false,
    this.showChevron = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool selected;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = destructive
        ? scheme.error
        : (selected ? AppColors.primaryDeepFor(context) : scheme.onSurface);

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: selected ? scheme.surfaceContainerLow : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceSm,
              ),
              child: Row(
                children: [
                  AppIconBadge(
                    icon: icon,
                    color: destructive ? scheme.error : scheme.onSurface,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.settingsLabel(color: titleColor),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                  if (trailing == null && showChevron)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSizes.spaceXxs),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

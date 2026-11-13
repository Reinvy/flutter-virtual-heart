// Komponen shared — SectionCard & sectionHeader (docs/DESIGN.md §3.6)
//
// Kartu datar dengan border hairline 1px dan divider penuh — tanpa shadow.
import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

/// Judul section: ikon 16px + teks uppercase wide-tracked.
Widget sectionHeader(
  BuildContext context,
  String title,
  IconData icon, {
  Widget? trailing,
}) {
  final mutedColor = AppColors.textSecondaryFor(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSizes.spaceXxs,
      0,
      AppSizes.spaceXxs,
      AppSizes.spaceSm - 2,
    ),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: mutedColor),
        const SizedBox(width: AppSizes.spaceXs),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionLabel(color: mutedColor),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Kartu section: surface datar + hairline border 1px + divider penuh antar anak.
Widget sectionCard({
  required BuildContext context,
  required List<Widget> children,
}) {
  final scheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(AppSizes.radiusCard);
  return Material(
    color: scheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: scheme.outlineVariant, width: 1),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        ],
      ],
    ),
  );
}

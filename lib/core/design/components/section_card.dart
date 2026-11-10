// Komponen shared — SectionCard & sectionHeader (docs/DESIGN.md §3.6)
//
// Menggunakan ColorScheme tema (tanpa branch isDark manual).
import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_effects.dart';
import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';
import 'app_icon_badge.dart';

/// Judul section: ikon dalam badge + teks uppercase.
Widget sectionHeader(
  BuildContext context,
  String title,
  IconData icon, {
  Widget? trailing,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSizes.spaceXxs,
      0,
      AppSizes.spaceXxs,
      AppSizes.spaceSm - 2,
    ),
    child: Row(
      children: [
        AppIconBadge(icon: icon, size: AppSizes.iconBadgeSm),
        const SizedBox(width: AppSizes.spaceXs + 2),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionLabel(
              color: AppColors.primaryDeepFor(context),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Kartu section: surface + hairline + shadow kartu, divider antar anak.
///
/// Memakai [Material] agar ink splash anak-anaknya tetap tergambar.
Widget sectionCard({
  required BuildContext context,
  required List<Widget> children,
}) {
  final scheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(AppSizes.radiusCard);
  return Container(
    decoration: BoxDecoration(
      borderRadius: radius,
      boxShadow: AppShadows.card(context),
    ),
    child: Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSizes.spaceMd,
                endIndent: AppSizes.spaceMd,
                color: scheme.outlineVariant,
              ),
          ],
        ],
      ),
    ),
  );
}

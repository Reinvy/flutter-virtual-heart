// Komponen shared — SectionCard & sectionHeader (docs/DESIGN.md §3.6)
//
// Menggunakan ColorScheme tema (tanpa branch isDark manual).
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

/// Judul section: ikon + teks uppercase berwarna primary.
Widget sectionHeader(BuildContext context, String title, IconData icon) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(
      bottom: AppSizes.spaceXs,
      left: AppSizes.spaceXxs,
    ),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm + 2, color: scheme.primary),
        const SizedBox(width: AppSizes.spaceXs),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionLabel(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    ),
  );
}

/// Kartu section: surface + radius [AppSizes.radiusLg] + divider antar anak.
///
/// Memakai [Material] (bukan `Container` berwarna) agar `ListTile` di dalamnya
/// tetap bisa menggambar ink splash dan tidak memicu debug error Flutter.
Widget sectionCard({
  required BuildContext context,
  required List<Widget> children,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Material(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
              color: scheme.outlineVariant,
            ),
        ],
      ],
    ),
  );
}

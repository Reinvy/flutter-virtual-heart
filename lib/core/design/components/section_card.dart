// Komponen shared — SectionCard & sectionHeader (docs/DESIGN.md §3.6)
//
// Diambil dari settings `section_widgets.dart`, dimigrasi ke core/design agar
// dipakai lintas fitur.
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_sizes.dart';

/// Judul section: ikon + teks uppercase berwarna primary.
Widget sectionHeader(BuildContext context, String title, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.spaceXs, left: AppSizes.spaceXxs),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm + 2, color: AppColors.primary),
        const SizedBox(width: AppSizes.spaceXs),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

/// Kartu section: surface + radius [AppSizes.radiusLg] + divider antar anak.
Widget sectionCard({required BuildContext context, required List<Widget> children}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    child: Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              indent: AppSizes.spaceMd,
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.divider,
            ),
        ],
      ],
    ),
  );
}

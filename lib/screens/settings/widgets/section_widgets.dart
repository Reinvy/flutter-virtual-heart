import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

// ── Section header ────────────────────────────────────────────────────────────

Widget sectionHeader(BuildContext context, String title, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm, left: AppSizes.xs),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm + 2, color: AppColors.primary),
        const SizedBox(width: AppSizes.sm),
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

// ── Section card ──────────────────────────────────────────────────────────────

Widget sectionCard({required BuildContext context, required List<Widget> children}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.surface : AppColors.surfaceLight,
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
              indent: AppSizes.md,
              color: isDark ? AppColors.surfaceAlt : const Color(0xFFEFE8F5),
            ),
        ],
      ],
    ),
  );
}

// Komponen shared — empty state seragam (docs/DESIGN.md §3.7).
import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = iconColor ?? scheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 44, color: color),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            Text(
              title,
              style: AppTextStyles.headingLarge(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spaceXs),
            Text(
              body,
              style: AppTextStyles.bodyMedium(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSizes.spaceLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// Fitur Persona (FR-03) — katalog opsi bersama untuk setup & edit.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';

/// Daftar hobi pilihan (katalog tunggal).
const kHobbiesList = [
  'Reading',
  'Music',
  'Cooking',
  'Sports',
  'Watching Movies',
  'Gaming',
  'Art & Design',
  'Traveling',
  'Yoga & Meditation',
  'Anime & Manga',
  'Photography',
  'Writing',
];

/// Chip hobi yang bisa dipilih; target sentuh minimal [AppSizes.touchTarget].
class HobbyChip extends StatelessWidget {
  const HobbyChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer : scheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.primaryDeepFor(context) : scheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.settingsLabel(
              color: isSelected
                  ? AppColors.primaryDeepFor(context)
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

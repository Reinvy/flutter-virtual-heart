// Fitur Persona (FR-03) — katalog opsi bersama untuk setup & edit.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/persona_config.dart';

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

/// Data visual satu preset kepribadian: emoji, label, deskripsi.
({String emoji, String label, String description}) personalityVisual(
  AppStrings strings,
  PersonalityPreset preset,
) {
  return switch (preset) {
    PersonalityPreset.gentle => (
      emoji: '🌸',
      label: strings.personaPersonalityGentle,
      description: strings.personaPersonalityGentleDesc,
    ),
    PersonalityPreset.cheerful => (
      emoji: '✨',
      label: strings.personaPersonalityCheerful,
      description: strings.personaPersonalityCheerfulDesc,
    ),
    PersonalityPreset.mature => (
      emoji: '🌙',
      label: strings.personaPersonalityMature,
      description: strings.personaPersonalityMatureDesc,
    ),
    PersonalityPreset.mysterious => (
      emoji: '🔮',
      label: strings.personaPersonalityMysterious,
      description: strings.personaPersonalityMysteriousDesc,
    ),
  };
}

/// Kartu pilihan gender (ikon + label).
class GenderOptionCard extends StatelessWidget {
  const GenderOptionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusPanel);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.65)
                : scheme.surface,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceSm,
                vertical: 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.14)
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: selected
                          ? AppColors.primaryDeepFor(context)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXs),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.settingsLabel(
                      color: selected
                          ? AppColors.primaryDeepFor(context)
                          : scheme.onSurface,
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

/// Kartu pilihan kepribadian; [compact] untuk grid dua kolom.
class PersonalityOptionCard extends ConsumerWidget {
  const PersonalityOptionCard({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final PersonalityPreset preset;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final data = personalityVisual(ref.watch(appStringsProvider), preset);
    final radius = BorderRadius.circular(AppSizes.radiusPanel);

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.55)
                : scheme.surface,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: EdgeInsets.all(compact ? AppSizes.spaceSm : AppSizes.spaceMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                    ),
                    child: Text(data.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.label,
                          style: AppTextStyles.settingsLabel(
                            color: selected
                                ? AppColors.primaryDeepFor(context)
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXxs - 2),
                        Text(
                          data.description,
                          style: AppTextStyles.bodySmall(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSizes.spaceXxs),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: scheme.primary,
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
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppDurations.durationFast,
            curve: AppDurations.curveStandard,
            constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceMd,
              vertical: 6,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? scheme.primaryContainer : scheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
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
      ),
    );
  }
}

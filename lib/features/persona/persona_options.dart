// Fitur Persona (FR-03) — katalog opsi bersama untuk setup & edit.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/components/app_icon_badge.dart';
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

/// Validasi nama persona (2..32 karakter).
String? validatePersonaName(AppStrings strings, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return strings.personaNameEmpty;
  if (text.length < 2) return strings.personaNameMin;
  if (text.length > 32) return strings.personaNameMax;
  return null;
}

/// Validasi panggilan untuk pengguna (1..32 karakter).
String? validatePersonaNickname(AppStrings strings, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return strings.personaNicknameEmpty;
  if (text.length > 32) return strings.personaNameMax;
  return null;
}
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

/// Kartu pilihan gender horizontal dengan AppIconBadge + indikator radio.
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
    final radius = BorderRadius.circular(AppSizes.radiusMd);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? scheme.surfaceContainerLow : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceSm,
                vertical: AppSizes.spaceSm,
              ),
              child: Row(
                children: [
                  AppIconBadge(
                    icon: icon,
                    size: 36,
                    color: selected
                        ? AppColors.primaryDeepFor(context)
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.settingsLabel(
                        color: selected
                            ? AppColors.primaryDeepFor(context)
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceXs),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? scheme.primary : scheme.outline,
                        width: selected ? 5 : 1.5,
                      ),
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

/// Kartu pilihan kepribadian dengan garis aksen kiri 3px saat aktif.
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
        color: selected ? scheme.surfaceContainerLow : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: AppDurations.durationFast,
                  width: 3,
                  color: selected ? scheme.primary : Colors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(
                      compact ? AppSizes.spaceSm : AppSizes.spaceMd,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            data.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spaceSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.label,
                                style: AppTextStyles.headingSmall(
                                  context,
                                  color: selected
                                      ? AppColors.primaryDeepFor(context)
                                      : scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip hobi editorial (`radiusSm` 8); fill terbalik saat terpilih.
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
    final radius = BorderRadius.circular(AppSizes.radiusSm);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
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
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : scheme.surface,
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.titleSmall(
                    color: isSelected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

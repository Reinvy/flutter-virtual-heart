// Fitur Persona (FR-10) — bottom sheet profil persona (dari chat).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/app_sheet.dart';
import '../../core/design/components/bloom_mark.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/sheet_header.dart';
import '../../core/design/mood_visuals.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/mood_state.dart';
import '../../models/persona_config.dart';
import '../chat/mood_provider.dart';
import 'avatar_catalog.dart';
import 'persona_options.dart';

/// Menampilkan bottom sheet profil persona.
///
/// Kembali `true` bila pengguna menekan tombol Edit — pemanggil yang membuka
/// form edit (`PersonaEditSheet`), sehingga alur edit tidak lagi bergantung
/// pada route `/persona-setup`.
Future<bool?> showPersonaProfileSheet(BuildContext context, PersonaConfig? persona) {
  return showAppSheet<bool>(
    context,
    child: PersonaProfileSheet(persona: persona),
  );
}

class PersonaProfileSheet extends ConsumerWidget {
  const PersonaProfileSheet({super.key, this.persona});

  final PersonaConfig? persona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);
    final strings = ref.read(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.64,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusSheet),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: AppSizes.spaceXl),
            children: [
              const SizedBox(height: 10),
              appSheetHandle(context),
              appSheetHeader(
                context,
                title: strings.settingsPersona,
                onClose: () => Navigator.of(context).pop(),
                closeTooltip: strings.commonClose,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(context, ref),
                    const SizedBox(height: AppSizes.spaceLg),
                    _buildMoodSection(mood, context, ref),
                    if ((persona?.hobbies ?? []).isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spaceLg),
                      _buildHobbiesSection(context, ref),
                    ],
                    const SizedBox(height: AppSizes.spaceLg),
                    _buildPersonalitySection(context, ref),
                    const SizedBox(height: AppSizes.spaceLg),
                    PrimaryButton(
                      label: strings.settingsEditPersona,
                      icon: Icons.edit_outlined,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.read(appStringsProvider);
    final genderLabel = (persona?.gender == PersonaGender.boyfriend)
        ? strings.personaGenderBoyfriend
        : strings.personaGenderGirlfriend;
    final nickname = persona?.nicknameForUser ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: AppGradients.profileHeader(context)),
        padding: const EdgeInsets.all(AppSizes.spaceMd + 4),
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -20,
              child: Opacity(
                opacity: 0.18,
                child: const BloomMark(size: 120, glow: false),
              ),
            ),
            Column(
              children: [
                avatarCircle(
                  context,
                  avatarOptForId(persona?.avatarId),
                  AppSizes.avatarProfile,
                ),
                const SizedBox(height: AppSizes.spaceMd),
                Text(
                  persona?.name ?? strings.appName,
                  style: AppTextStyles.displaySmall(color: scheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  genderLabel,
                  style: AppTextStyles.bodySmall(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                if (nickname.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.spaceXxs),
                  Text(
                    fillPlaceholders(strings.personaCallsYou, {
                      'nickname': nickname,
                    }),
                    style: AppTextStyles.bodySmall(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection(MoodState mood, BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.read(appStringsProvider);
    final color = moodColor(context, mood.current);
    final intensityPct = (mood.intensity * 100).round();
    final motionOk = !MediaQuery.disableAnimationsOf(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.14), scheme.surface],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusPanel),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
            ),
            child: Text(
              moodEmoji(mood.current),
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.chatCurrentMood,
                  style: AppTextStyles.caption(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  moodLabel(strings, mood.current),
                  style: AppTextStyles.headingSmall(color: color),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$intensityPct%',
                style: AppTextStyles.settingsLabel(color: color),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                height: 6,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: mood.intensity),
                  duration: motionOk ? const Duration(milliseconds: 400) : Duration.zero,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: color.withValues(alpha: 0.2),
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHobbiesSection(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.read(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.personaHobbies,
          style: AppTextStyles.headingSmall(
            color: scheme.onSurface,
          ).copyWith(fontSize: 17),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Wrap(
          spacing: AppSizes.spaceXs,
          runSpacing: AppSizes.spaceXs,
          children: [
            for (final hobby in persona?.hobbies ?? <String>[])
              Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceSm + 2,
                  vertical: 8,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  hobby,
                  style: AppTextStyles.bodySmall(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalitySection(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.read(appStringsProvider);
    final preset = persona?.personalityPreset ?? PersonalityPreset.gentle;
    final data = personalityVisual(strings, preset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.personaPersonality,
          style: AppTextStyles.headingSmall(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSizes.radiusControl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: AppTextStyles.settingsLabel(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceXxs - 2),
                    Text(
                      data.description,
                      style: AppTextStyles.bodySmall(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

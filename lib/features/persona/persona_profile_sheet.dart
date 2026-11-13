// Fitur Persona (FR-10) — bottom sheet profil dossier persona.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/app_sheet.dart';
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
import 'persona_controller.dart';
import 'persona_options.dart';
/// Menampilkan bottom sheet profil persona.
///
/// Kembali `true` bila pengguna menekan tombol Edit.
Future<bool?> showPersonaProfileSheet(
  BuildContext context,
  PersonaConfig? persona,
) {
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
    final livePersona = ref.watch(personaProvider) ?? persona;
    final mood = ref.watch(moodProvider);
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusSheet),
            ),
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              appSheetHandle(context),
              appSheetHeader(
                context,
                title: strings.settingsPersona,
                onClose: () => Navigator.of(context).pop(),
                closeTooltip: strings.commonClose,
              ),
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSizes.spaceMd),
                  children: [
                    _buildHero(context, strings, livePersona),
                    const SizedBox(height: AppSizes.spaceMd),
                    _buildMoodTelemetry(mood, context, strings),
                    const SizedBox(height: AppSizes.spaceLg),
                    _buildPersonalitySection(context, strings, livePersona),
                    if ((livePersona?.hobbies ?? []).isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spaceLg),
                      _buildHobbiesSection(context, strings, livePersona),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spaceMd,
                      vertical: AppSizes.spaceSm,
                    ),
                    child: PrimaryButton(
                      label: strings.settingsEditPersona,
                      icon: Icons.edit_outlined,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(
    BuildContext context,
    AppStrings strings,
    PersonaConfig? active,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final genderLabel = (active?.gender == PersonaGender.boyfriend)
        ? strings.personaGenderBoyfriend
        : strings.personaGenderGirlfriend;
    final nickname = active?.nicknameForUser ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: AppBorders.cardDecoration(
        context,
        color: scheme.surfaceContainerLow,
      ),
      child: Column(
        children: [
          avatarCircle(
            context,
            avatarOptForId(active?.avatarId),
            AppSizes.avatarProfile,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          Text(
            active?.name ?? strings.appName,
            style: AppTextStyles.displaySmall(context, color: scheme.onSurface),
            textAlign: TextAlign.center,
          ),
          Text(
            genderLabel,
            style: AppTextStyles.bodySmall(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (nickname.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spaceXxs),
            Text(
              fillPlaceholders(strings.personaCallsYou, {'nickname': nickname}),
              style: AppTextStyles.bodySmall(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodTelemetry(
    MoodState mood,
    BuildContext context,
    AppStrings strings,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final color = moodColor(context, mood.current);
    final intensityPct = (mood.intensity * 100).round();
    final motionOk = !MediaQuery.disableAnimationsOf(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: AppBorders.cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  moodEmoji(mood.current),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.chatCurrentMood.toUpperCase(),
                      style: AppTextStyles.sectionLabel(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moodLabel(strings, mood.current),
                      style: AppTextStyles.headingSmall(context, color: color),
                    ),
                  ],
                ),
              ),
              Text(
                '$intensityPct%',
                style: AppTextStyles.caption(
                  color: color,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceSm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: mood.intensity.clamp(0, 1)),
            duration: motionOk ? const Duration(milliseconds: 400) : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: scheme.surfaceContainerHighest,
                color: color,
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHobbiesSection(
    BuildContext context,
    AppStrings strings,
    PersonaConfig? active,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.personaHobbies.toUpperCase(),
          style: AppTextStyles.sectionLabel(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Wrap(
          spacing: AppSizes.spaceXs,
          runSpacing: AppSizes.spaceXs,
          children: [
            for (final hobby in active?.hobbies ?? <String>[])
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceSm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  strings.personaHobbyLabel(hobby),
                  style: AppTextStyles.bodySmall(color: scheme.onSurface),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalitySection(
    BuildContext context,
    AppStrings strings,
    PersonaConfig? active,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final preset = active?.personalityPreset ?? PersonalityPreset.gentle;
    final data = personalityVisual(strings, preset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.personaPersonality.toUpperCase(),
          style: AppTextStyles.sectionLabel(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: AppBorders.cardDecoration(
            context,
            color: scheme.surfaceContainerLow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: AppTextStyles.headingSmall(
                        context,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
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

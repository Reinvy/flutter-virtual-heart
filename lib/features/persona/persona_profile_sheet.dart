// Fitur Persona (FR-10) — bottom sheet profil persona (dari chat).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/components/sakura_divider.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/mood_state.dart';
import '../../models/persona_config.dart';
import '../chat/mood_provider.dart';

/// Menampilkan bottom sheet profil persona.
void showPersonaProfileSheet(BuildContext context, PersonaConfig? persona) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PersonaProfileSheet(persona: persona),
  );
}

class PersonaProfileSheet extends ConsumerWidget {
  const PersonaProfileSheet({super.key, this.persona});

  final PersonaConfig? persona;

  static const Map<MoodType, Color> _moodColors = {
    MoodType.happy: AppColors.primaryDeep,
    MoodType.longing: AppColors.secondary,
    MoodType.playful: Color(0xFFD4739D),
    MoodType.sad: AppColors.secondarySoft,
    MoodType.excited: AppColors.accent,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
            children: [
              const SizedBox(height: AppSizes.md),
              _buildNameSection(context, ref),
              const SakuraDivider(),
              _buildMoodSection(mood, context, ref),
              const SizedBox(height: AppSizes.lg),
              if ((persona?.hobbies ?? []).isNotEmpty) ...[
                _buildHobbiesSection(context, ref),
                const SizedBox(height: AppSizes.lg),
              ],
              _buildPersonalitySection(context, ref),
              const SizedBox(height: AppSizes.xl),
              _buildEditButton(context, ref),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameSection(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.read(appStringsProvider);
    final subtleColor = scheme.onSurfaceVariant;
    final genderLabel = (persona?.gender == PersonaGender.boyfriend)
        ? strings.personaGenderBoyfriend
        : strings.personaGenderGirlfriend;
    final nickname = persona?.nicknameForUser ?? '';

    return Column(
      children: [
        Text(
          persona?.name ?? 'VirtualHeart',
          style: AppTextStyles.headingLarge(color: scheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          genderLabel,
          style: AppTextStyles.bodyMedium(color: subtleColor),
          textAlign: TextAlign.center,
        ),
        if (nickname.isNotEmpty) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            fillPlaceholders(strings.personaCallsYou, {'nickname': nickname}),
            style: AppTextStyles.bodyMedium(color: subtleColor),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildMoodSection(MoodState mood, BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final subtleColor = scheme.onSurfaceVariant;
    final strings = ref.read(appStringsProvider);
    final emoji = switch (mood.current) {
      MoodType.happy => '😊',
      MoodType.longing => '🥺',
      MoodType.playful => '😄',
      MoodType.sad => '😢',
      MoodType.excited => '🤩',
    };
    final label = switch (mood.current) {
      MoodType.happy => strings.moodHappy,
      MoodType.longing => strings.moodLonging,
      MoodType.playful => strings.moodPlayful,
      MoodType.sad => strings.moodSad,
      MoodType.excited => strings.moodExcited,
    };
    final color = _moodColors[mood.current] ?? AppColors.primaryDeep;
    final intensityPct = (mood.intensity * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.chatCurrentMood, style: AppTextStyles.moodIndicator(color: subtleColor)),
                const SizedBox(height: AppSizes.xs),
                Text(label, style: AppTextStyles.headingSmall(color: color)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$intensityPct%', style: AppTextStyles.headingSmall(color: color)),
              const SizedBox(height: AppSizes.xs),
              SizedBox(
                width: 64,
                child: LinearProgressIndicator(
                  value: mood.intensity,
                  backgroundColor: color.withValues(alpha: 0.2),
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHobbiesSection(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.personaHobbies,
          style: AppTextStyles.headingSmall(color: AppColors.primaryDeep),
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: (persona?.hobbies ?? []).map((hobby) => _HobbyChip(label: hobby)).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalitySection(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.read(appStringsProvider);
    final subtleColor = scheme.onSurfaceVariant;
    final cardBg = scheme.surfaceContainerLow;
    final preset = persona?.personalityPreset ?? PersonalityPreset.gentle;

    final (emoji, label, description) = switch (preset) {
      PersonalityPreset.gentle => (
        '🌸',
        strings.personaPersonalityGentle,
        strings.personaPersonalityGentleDesc,
      ),
      PersonalityPreset.cheerful => (
        '✨',
        strings.personaPersonalityCheerful,
        strings.personaPersonalityCheerfulDesc,
      ),
      PersonalityPreset.mature => (
        '🌙',
        strings.personaPersonalityMature,
        strings.personaPersonalityMatureDesc,
      ),
      PersonalityPreset.mysterious => (
        '🔮',
        strings.personaPersonalityMysterious,
        strings.personaPersonalityMysteriousDesc,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.personaPersonality,
          style: AppTextStyles.headingSmall(color: AppColors.primaryDeep),
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.settingsLabel(color: scheme.onSurface)),
                    const SizedBox(height: AppSizes.xs),
                    Text(description, style: AppTextStyles.bodyMedium(color: subtleColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    return PrimaryButton(
      label: strings.settingsEditPersona,
      icon: Icons.edit_outlined,
      onPressed: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.personaSetup);
      },
    );
  }
}

class _HobbyChip extends StatelessWidget {
  const _HobbyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.primaryDeep.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium(color: AppColors.primaryDeep),
      ),
    );
  }
}

// Fitur Persona (FR-10) — bottom sheet profil persona (dari chat).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/mood_state.dart';
import '../../models/persona_config.dart';
import '../chat/mood_provider.dart';
import 'avatar_catalog.dart';

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

  static const Map<PersonalityPreset, ({String emoji, String label, String description})>
  _personalityInfo = {
    PersonalityPreset.gentle: (
      emoji: '🌸',
      label: 'Gentle',
      description: 'Caring, warm, and always there for you',
    ),
    PersonalityPreset.cheerful: (
      emoji: '✨',
      label: 'Cheerful',
      description: 'Full of energy, loves joking, and uplifting',
    ),
    PersonalityPreset.mature: (
      emoji: '🌙',
      label: 'Mature',
      description: 'Wise, calm, and dependable',
    ),
    PersonalityPreset.mysterious: (
      emoji: '🔮',
      label: 'Mysterious',
      description: 'Intriguing, full of puzzles, and captivating',
    ),
  };

  static const Map<MoodType, ({String emoji, String label})> _moodInfo = {
    MoodType.happy: (emoji: '😊', label: 'Happy'),
    MoodType.longing: (emoji: '🥺', label: 'Missing You'),
    MoodType.playful: (emoji: '😄', label: 'Playful'),
    MoodType.sad: (emoji: '😢', label: 'Sad'),
    MoodType.excited: (emoji: '🤩', label: 'Excited'),
  };

  static const Map<MoodType, Color> _moodColors = {
    MoodType.happy: Color(0xFFC2507A),
    MoodType.longing: Color(0xFF7B5EA7),
    MoodType.playful: Color(0xFFD4739D),
    MoodType.sad: Color(0xFF7B5EA7),
    MoodType.excited: Color(0xFFE8506A),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
            children: [
              _DragHandle(),
              const SizedBox(height: AppSizes.md),
              _buildAvatar(),
              const SizedBox(height: AppSizes.md),
              _buildNameSection(context),
              const SizedBox(height: AppSizes.lg),
              _buildMoodSection(mood, context, ref),
              const SizedBox(height: AppSizes.lg),
              if ((persona?.hobbies ?? []).isNotEmpty) ...[
                _buildHobbiesSection(),
                const SizedBox(height: AppSizes.lg),
              ],
              _buildPersonalitySection(context),
              const SizedBox(height: AppSizes.xl),
              _buildEditButton(context, ref),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: personaAvatar(
        name: persona?.name,
        avatarId: persona?.avatarId,
        size: AppSizes.avatarLg,
        textStyle: AppTextStyles.appName(color: Colors.white).copyWith(fontSize: 36),
      ),
    );
  }

  Widget _buildNameSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final genderLabel = (persona?.gender == PersonaGender.boyfriend) ? 'Boyfriend' : 'Girlfriend';
    final nickname = persona?.nicknameForUser ?? '';

    return Column(
      children: [
        Text(
          persona?.name ?? 'VirtualHeart',
          style: AppTextStyles.headingLarge(color: textColor),
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
            'Calls you "$nickname"',
            style: AppTextStyles.bodyMedium(color: subtleColor),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildMoodSection(MoodState mood, BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final strings = ref.read(appStringsProvider);
    final info = _moodInfo[mood.current] ?? (emoji: '😊', label: strings.moodHappy);
    final color = _moodColors[mood.current] ?? AppColors.primary;
    final intensityPct = (mood.intensity * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.chatCurrentMood, style: AppTextStyles.moodIndicator(color: subtleColor)),
                const SizedBox(height: AppSizes.xs),
                Text(info.label, style: AppTextStyles.headingSmall(color: color)),
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
                  backgroundColor: color.withAlpha(40),
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

  Widget _buildHobbiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hobbies & Interests', style: AppTextStyles.headingSmall(color: AppColors.primary)),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: (persona?.hobbies ?? []).map((hobby) => _HobbyChip(label: hobby)).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalitySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final preset = persona?.personalityPreset ?? PersonalityPreset.gentle;
    final info =
        _personalityInfo[preset] ??
        (label: 'Gentle', emoji: '🌸', description: 'Caring, warm, and always there for you');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personality', style: AppTextStyles.headingSmall(color: AppColors.primary)),
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
              Text(info.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.label, style: AppTextStyles.settingsLabel(color: textColor)),
                    const SizedBox(height: AppSizes.xs),
                    Text(info.description, style: AppTextStyles.bodyMedium(color: subtleColor)),
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

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary).withAlpha(100),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
      ),
    );
  }
}

class _HobbyChip extends StatelessWidget {
  const _HobbyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Text(label, style: AppTextStyles.bodyMedium(color: AppColors.primary)),
    );
  }
}

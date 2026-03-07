import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/mood_state.dart';
import '../../../data/models/persona_config.dart';
import '../../../providers/mood_provider.dart';
import '../../../providers/router_provider.dart';

/// Bottom sheet displaying the persona's profile:
/// large avatar, name, personality, hobbies, and current mood.
/// Triggered by tapping the avatar / name area in the chat AppBar.
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

  // ── Avatar color map (mirrors _AppBarAvatar in chat_screen.dart) ──────────
  static const Map<String, Color> _avatarColors = {
    'gf_1': Color(0xFFC2507A),
    'gf_2': Color(0xFF7B5EA7),
    'gf_3': Color(0xFFE8506A),
    'gf_4': Color(0xFFD4739A),
    'gf_5': Color(0xFF9B6EBA),
    'gf_6': Color(0xFFC47BAA),
    'bf_1': Color(0xFF5B8CCC),
    'bf_2': Color(0xFF7B5EA7),
    'bf_3': Color(0xFF3D8B6E),
    'bf_4': Color(0xFF4E7AA0),
    'bf_5': Color(0xFF6472B5),
    'bf_6': Color(0xFF5D9E8C),
  };

  static const Map<PersonalityPreset, ({String label, String emoji, String description})>
  _personalityInfo = {
    PersonalityPreset.gentle: (
      label: 'Gentle',
      emoji: '🌸',
      description: 'Caring, warm, and always there for you',
    ),
    PersonalityPreset.cheerful: (
      label: 'Cheerful',
      emoji: '✨',
      description: 'Full of energy, loves joking, and uplifting',
    ),
    PersonalityPreset.mature: (
      label: 'Mature',
      emoji: '🌙',
      description: 'Wise, calm, and dependable',
    ),
    PersonalityPreset.mysterious: (
      label: 'Mysterious',
      emoji: '🔮',
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
    MoodType.playful: Color(0xFFE8839F),
    MoodType.sad: Color(0xFF5B8CCC),
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
            color: isDark ? AppColors.surfaceAlt : AppColors.surfaceAltLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
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
              _buildMoodSection(mood, context),
              const SizedBox(height: AppSizes.lg),
              if ((persona?.hobbies ?? []).isNotEmpty) ...[
                _buildHobbiesSection(),
                const SizedBox(height: AppSizes.lg),
              ],
              _buildPersonalitySection(context),
              const SizedBox(height: AppSizes.xl),
              _buildEditButton(context),
            ],
          ),
        );
      },
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final color = _avatarColors[persona?.avatarId] ?? AppColors.primary;
    final initial = (persona?.name.isNotEmpty ?? false) ? persona!.name[0].toUpperCase() : '♥';

    return Center(
      child: Container(
        width: AppSizes.avatarLg,
        height: AppSizes.avatarLg,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [color.withAlpha(220), color.withAlpha(160)],
            radius: 0.85,
          ),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 24, spreadRadius: 4)],
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: AppTextStyles.appName(color: Colors.white).copyWith(fontSize: 36),
        ),
      ),
    );
  }

  // ── Name + nickname ───────────────────────────────────────────────────────

  Widget _buildNameSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
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

  // ── Mood ──────────────────────────────────────────────────────────────────

  Widget _buildMoodSection(MoodState mood, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final info = _moodInfo[mood.current] ?? (emoji: '😊', label: 'Bahagia');
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
                Text('Current Mood', style: AppTextStyles.moodIndicator(color: subtleColor)),
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

  // ── Hobbies ───────────────────────────────────────────────────────────────

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

  // ── Personality ───────────────────────────────────────────────────────────

  Widget _buildPersonalitySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.surface : AppColors.surfaceLight;
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

  // ── Edit button ───────────────────────────────────────────────────────────

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.personaSetup);
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Persona'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          textStyle: AppTextStyles.button(),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color:
              (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight)
                  .withAlpha(100),
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
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Text(label, style: AppTextStyles.bodyMedium(color: AppColors.primary)),
    );
  }
}

// Fitur Chat (FR-09) — indikator mood di app bar (docs/DESIGN.md §3.4).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/mood_state.dart';
import '../mood_provider.dart';

/// Subtitle AppBar chat: emoji + label mood persona.
class MoodIndicator extends ConsumerWidget {
  const MoodIndicator({super.key});

  static const Map<MoodType, String> _emoji = {
    MoodType.happy: '😊',
    MoodType.longing: '🥺',
    MoodType.playful: '😄',
    MoodType.sad: '😢',
    MoodType.excited: '🤩',
  };

  String _label(AppStrings strings, MoodType mood) => switch (mood) {
    MoodType.happy => strings.moodHappy,
    MoodType.longing => strings.moodLonging,
    MoodType.playful => strings.moodPlayful,
    MoodType.sad => strings.moodSad,
    MoodType.excited => strings.moodExcited,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final mood = ref.watch(moodProvider);
    final emoji = _emoji[mood.current] ?? '😊';
    final label = _label(strings, mood.current);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      '$emoji $label',
      style: AppTextStyles.moodIndicator(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
      ),
    );
  }
}

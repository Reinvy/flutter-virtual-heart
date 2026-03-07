import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/mood_state.dart';
import '../../../providers/mood_provider.dart';

/// Subtitle widget for the chat AppBar showing the persona's current mood.
class MoodIndicator extends ConsumerWidget {
  const MoodIndicator({super.key});

  static const Map<MoodType, String> _emoji = {
    MoodType.happy: '😊',
    MoodType.longing: '🥺',
    MoodType.playful: '😄',
    MoodType.sad: '😢',
    MoodType.excited: '🤩',
  };

  static const Map<MoodType, String> _label = {
    MoodType.happy: 'bahagia',
    MoodType.longing: 'merindukanmu',
    MoodType.playful: 'playful',
    MoodType.sad: 'sedih',
    MoodType.excited: 'bersemangat',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);
    final emoji = _emoji[mood.current] ?? '😊';
    final label = _label[mood.current] ?? 'bahagia';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      '$emoji $label',
      style: AppTextStyles.moodIndicator(
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
      ),
    );
  }
}

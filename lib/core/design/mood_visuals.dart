// Visual mood bersama (FR-09) — satu sumber emoji, label, dan warna.
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../../models/mood_state.dart';
import 'tokens/app_colors.dart';

/// Emoji yang dipakai indikator mood di AppBar chat & profil persona.
String moodEmoji(MoodType mood) => switch (mood) {
  MoodType.happy => '😊',
  MoodType.longing => '🥺',
  MoodType.playful => '😄',
  MoodType.sad => '😢',
  MoodType.excited => '🤩',
};

/// Label mood terlokalisasi.
String moodLabel(AppStrings strings, MoodType mood) => switch (mood) {
  MoodType.happy => strings.moodHappy,
  MoodType.longing => strings.moodLonging,
  MoodType.playful => strings.moodPlayful,
  MoodType.sad => strings.moodSad,
  MoodType.excited => strings.moodExcited,
};

/// Warna mood brightness-aware (aman untuk teks kecil di light & dark).
Color moodColor(BuildContext context, MoodType mood) => switch (mood) {
  MoodType.happy => Theme.of(context).colorScheme.primary,
  MoodType.longing => AppColors.secondaryFor(context),
  MoodType.playful => AppColors.accentDeepFor(context),
  MoodType.sad => AppColors.secondaryFor(context),
  MoodType.excited => AppColors.primaryDeepFor(context),
};

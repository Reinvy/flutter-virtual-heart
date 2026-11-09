// Visual mood bersama (FR-09) — satu sumber emoji untuk semua permukaan UI.
import '../../models/mood_state.dart';

/// Emoji yang dipakai indikator mood di AppBar chat & profil persona.
String moodEmoji(MoodType mood) => switch (mood) {
  MoodType.happy => '😊',
  MoodType.longing => '🥺',
  MoodType.playful => '😄',
  MoodType.sad => '😢',
  MoodType.excited => '🤩',
};

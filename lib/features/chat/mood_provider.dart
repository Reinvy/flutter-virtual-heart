// Fitur Chat (FR-09) — provider mood pasangan virtual.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/mood_state.dart';
import '../../services/mood_service.dart';

/// Mengekspos [MoodState] saat ini dan memungkinkan refresh setelah mutasi.
class MoodNotifier extends Notifier<MoodState> {
  @override
  MoodState build() => ref.read(moodServiceProvider).getCurrentMood();

  /// Membaca ulang [MoodState] yang tersimpan dari ObjectBox.
  void refresh() {
    state = ref.read(moodServiceProvider).getCurrentMood();
  }
}

final moodProvider = NotifierProvider<MoodNotifier, MoodState>(MoodNotifier.new);

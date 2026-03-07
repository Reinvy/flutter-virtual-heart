import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/mood_state.dart';
import '../services/mood_service.dart';

/// Exposes the current [MoodState] and allows refreshing it after mutations.
class MoodNotifier extends Notifier<MoodState> {
  @override
  MoodState build() => ref.read(moodServiceProvider).getCurrentMood();

  /// Re-reads the persisted [MoodState] from ObjectBox.
  void refresh() {
    state = ref.read(moodServiceProvider).getCurrentMood();
  }
}

final moodProvider = NotifierProvider<MoodNotifier, MoodState>(MoodNotifier.new);

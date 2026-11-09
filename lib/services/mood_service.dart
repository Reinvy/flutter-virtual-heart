import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood_state.dart';
import '../models/objectbox_provider.dart';
import 'mood_store.dart';

/// Menangani transisi state mood berdasarkan isi percakapan & waktu idle.
///
/// Semua perubahan state langsung dipersistensikan ke ObjectBox.
class MoodService {
  final MoodStore _db;

  MoodService(this._db);

  // ── Keyword lists for sentiment scoring ──────────────────────────────────
  //
  // Pencocokan memakai batas kata (bukan `contains`) supaya "crystal" tidak
  // terbaca "cry" dan "remain" tidak terbaca "main".

  static const _happyKeywords = [
    'senang',
    'bahagia',
    'senyum',
    'tersenyum',
    'suka',
    'cinta',
    'sayang',
    'indah',
    'cantik',
    'bagus',
    'keren',
    'mantap',
    'warm',
    'nyaman',
    'tenang',
    'happy',
    'love',
    'wonderful',
    'glad',
    'joy',
    'dekat',
    'bersamamu',
  ];

  static const _excitedKeywords = [
    'seru',
    'semangat',
    'antusias',
    'wow',
    'luar biasa',
    'bersemangat',
    'tidak sabar',
    'tidak tahan',
    'amazing',
    'excited',
    'fantastic',
    'awesome',
  ];

  static const _playfulKeywords = [
    'haha',
    'hihi',
    'wkwk',
    'hehe',
    'lucu',
    'bercanda',
    'jahil',
    'goda',
    'nakal',
    'gemas',
    'iseng',
    'main',
    'usil',
    'canda',
    'cute',
    'jail',
  ];

  static const _sadKeywords = [
    'sedih',
    'menangis',
    'galau',
    'kesepian',
    'hancur',
    'kecewa',
    'sakit',
    'lelah',
    'bosan',
    'putus asa',
    'tidak baik-baik saja',
    'susah',
    'berat',
    'down',
    'sad',
    'cry',
    'tears',
    'lonely',
    'hurt',
  ];

  /// Bobot tiap mood: sinyal negatif lebih dipercaya daripada sinyal positif.
  static const Map<MoodType, double> _weights = {
    MoodType.sad: 2.0,
    MoodType.excited: 1.5,
    MoodType.playful: 1.5,
    MoodType.happy: 1.0,
  };

  /// Urutan tie-break: sad, excited, playful, happy.
  static const List<MoodType> _priority = [
    MoodType.sad,
    MoodType.excited,
    MoodType.playful,
    MoodType.happy,
  ];

  static const Map<MoodType, double> _intensityCap = {
    MoodType.sad: 0.85,
    MoodType.playful: 0.90,
    MoodType.excited: 0.95,
    MoodType.happy: 0.85,
    MoodType.longing: 0.90,
  };

  static final Map<MoodType, List<RegExp>> _patterns = {
    for (final entry in {
      MoodType.happy: _happyKeywords,
      MoodType.excited: _excitedKeywords,
      MoodType.playful: _playfulKeywords,
      MoodType.sad: _sadKeywords,
    }.entries)
      entry.key: _compile(entry.value),
  };

  static List<RegExp> _compile(List<String> keywords) => [
    for (final keyword in keywords)
      RegExp(
        '(?<![A-Za-z0-9_])${RegExp.escape(keyword)}(?![A-Za-z0-9_])',
        caseSensitive: false,
      ),
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the current [MoodState], creating a default one if none exists.
  MoodState getCurrentMood() {
    final all = _db.moodStateBox.getAll();
    if (all.isNotEmpty) return all.first;
    final initial = MoodState();
    _db.moodStateBox.put(initial);
    return initial;
  }

  /// Updates mood from sentiment in the user's message and the AI reply.
  ///
  /// Records the interaction time, applies time-based decay, and persists.
  MoodState updateMoodFromConversation(String userMessage, String aiResponse) {
    final mood = getCurrentMood();
    final now = DateTime.now();
    _applyDecay(mood, now);

    final text = '$userMessage\n$aiResponse';
    MoodType? winner;
    var best = 0.0;
    for (final type in _priority) {
      final score = _matchCount(text, _patterns[type]!) * _weights[type]!;
      if (score > best) {
        best = score;
        winner = type;
      }
    }

    if (winner != null) {
      final cap = _intensityCap[winner] ?? 0.9;
      final changed = winner != mood.current;
      mood.current = winner;
      mood.intensity = changed
          ? min(cap, max(0.6, mood.intensity + 0.10))
          : min(cap, mood.intensity + 0.05);
    }

    mood.lastUpdatedAt = now;
    mood.lastInteractionAt = now;
    _db.moodStateBox.put(mood);
    return mood;
  }

  /// Degrades mood to [MoodType.longing] after prolonged inactivity.
  ///
  /// - ≥ 6 h idle → longing (moderate intensity)
  /// - ≥ 12 h idle → longing (high intensity)
  MoodState updateMoodFromIdleTime() {
    final mood = getCurrentMood();
    final idleHours = DateTime.now().difference(mood.lastInteractionAt).inHours;

    if (idleHours >= 12) {
      mood.current = MoodType.longing;
      mood.intensity = 0.90;
      mood.lastUpdatedAt = DateTime.now();
      _db.moodStateBox.put(mood);
    } else if (idleHours >= 6) {
      mood.current = MoodType.longing;
      mood.intensity = min(0.80, mood.intensity + 0.10);
      mood.lastUpdatedAt = DateTime.now();
      _db.moodStateBox.put(mood);
    }

    return mood;
  }

  /// Stamps the current time as the last interaction time without changing mood.
  void recordInteraction() {
    final mood = getCurrentMood();
    mood.lastInteractionAt = DateTime.now();
    _db.moodStateBox.put(mood);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static int _matchCount(String text, List<RegExp> patterns) {
    var count = 0;
    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) count++;
    }
    return count;
  }

  /// Intensitas meluruh pelan saat tidak ada percakapan (maks. 0.15/batch).
  static void _applyDecay(MoodState mood, DateTime now) {
    final hours = now.difference(mood.lastUpdatedAt).inMinutes / 60;
    if (hours <= 0) return;
    final decay = min(0.15, hours * 0.01);
    mood.intensity = max(0.3, mood.intensity - decay);
  }
}

final moodServiceProvider = Provider<MoodService>((ref) {
  return MoodService(ref.read(objectBoxServiceProvider));
});

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';

import '../models/mood_state.dart';
import '../models/objectbox_provider.dart';

/// Abstraksi penyimpanan mood — memungkinkan test memakai fake tanpa
/// membuka store ObjectBox asli.
abstract class MoodStore {
  Box<MoodState> get moodStateBox;
}

/// Menangani transisi state mood berdasarkan isi percakapan & waktu idle.
///
/// Semua perubahan state langsung dipersistensikan ke ObjectBox.
class MoodService {
  final MoodStore _db;

  MoodService(this._db);

  // ── Keyword lists for sentiment scoring ──────────────────────────────────

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

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the current [MoodState], creating a default one if none exists.
  MoodState getCurrentMood() {
    final all = _db.moodStateBox.getAll();
    if (all.isNotEmpty) return all.first;
    final initial = MoodState();
    _db.moodStateBox.put(initial);
    return initial;
  }

  /// Updates mood based on keyword sentiment in [aiResponse].
  ///
  /// Records the interaction time and persists the new state.
  MoodState updateMoodFromConversation(String aiResponse) {
    final mood = getCurrentMood();
    final lower = aiResponse.toLowerCase();

    int happyScore = 0;
    int excitedScore = 0;
    int playfulScore = 0;
    int sadScore = 0;

    for (final kw in _happyKeywords) {
      if (lower.contains(kw)) happyScore++;
    }
    for (final kw in _excitedKeywords) {
      if (lower.contains(kw)) excitedScore++;
    }
    for (final kw in _playfulKeywords) {
      if (lower.contains(kw)) playfulScore++;
    }
    for (final kw in _sadKeywords) {
      if (lower.contains(kw)) sadScore++;
    }

    final maxScore = max(max(happyScore, excitedScore), max(playfulScore, sadScore));

    if (maxScore > 0) {
      if (sadScore == maxScore) {
        mood.current = MoodType.sad;
        mood.intensity = min(0.85, mood.intensity + 0.10);
      } else if (playfulScore == maxScore) {
        mood.current = MoodType.playful;
        mood.intensity = min(0.90, mood.intensity + 0.10);
      } else if (excitedScore >= happyScore && excitedScore == maxScore) {
        mood.current = MoodType.excited;
        mood.intensity = min(0.95, mood.intensity + 0.15);
      } else if (happyScore > 0) {
        // Positive: lift from longing/sad to happy
        if (mood.current == MoodType.longing || mood.current == MoodType.sad) {
          mood.current = MoodType.happy;
        }
        mood.intensity = min(0.85, mood.intensity + 0.05);
      }
    }

    final now = DateTime.now();
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
}

final moodServiceProvider = Provider<MoodService>((ref) {
  return MoodService(ref.read(objectBoxServiceProvider));
});

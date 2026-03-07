import '../../data/models/memory_fact.dart';
import '../../data/models/message.dart';
import '../../data/models/mood_state.dart';
import '../../data/models/persona_config.dart';

/// Assembles LLM prompt strings from current app state.
///
/// All methods are static and pure — no side-effects or Riverpod dependencies.
class PromptBuilder {
  PromptBuilder._();

  /// Maximum number of recent messages to include in the prompt context.
  static const int maxRecentMessages = 20;

  static const Map<PersonalityPreset, String> _personalityDesc = {
    PersonalityPreset.gentle:
        'Lembut, penuh perhatian, selalu mendukung, berbicara hangat dan sabar.',
    PersonalityPreset.cheerful:
        'Ceria, energetik, suka bercanda, selalu membawa suasana menyenangkan.',
    PersonalityPreset.mature: 'Dewasa, bijaksana, tenang, memberikan pandangan yang mendalam.',
    PersonalityPreset.mysterious:
        'Misterius, penuh intrik, berbicara seperlunya namun selalu bermakna.',
  };

  static const Map<MoodType, String> _moodDesc = {
    MoodType.happy: 'bahagia',
    MoodType.longing: 'rindu',
    MoodType.playful: 'playful / gemas',
    MoodType.sad: 'sedih',
    MoodType.excited: 'bersemangat',
  };

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Builds the `[SYSTEM]` + optional `[CONTEXT SUMMARY]` block.
  ///
  /// Pass the returned string as the first argument of [buildFullPrompt].
  static String buildSystemPrompt(
    PersonaConfig persona,
    MoodState mood,
    List<MemoryFact> memoryFacts,
    String conversationSummary,
  ) {
    final genderDesc = persona.gender == PersonaGender.girlfriend ? 'perempuan' : 'laki-laki';
    final personalityDesc =
        _personalityDesc[persona.personalityPreset] ?? _personalityDesc[PersonalityPreset.gentle]!;
    final moodDesc = _moodDesc[mood.current] ?? 'bahagia';
    final intensityPct = (mood.intensity * 100).toStringAsFixed(0);

    final buf = StringBuffer();
    buf.writeln('[SYSTEM]');
    buf.writeln(
      'Kamu adalah ${persona.name}, seorang $genderDesc virtual yang menjadi '
      'pasangan ${persona.nicknameForUser}.',
    );
    buf.writeln('Kepribadian: $personalityDesc');

    if (persona.hobbies.isNotEmpty) {
      buf.writeln('Hobi: ${persona.hobbies.join(', ')}.');
    }

    buf.writeln('Mood saat ini: $moodDesc (intensitas: $intensityPct%).');
    buf.writeln('Sesuaikan nada bicaramu dengan mood tersebut secara halus dan natural.');
    buf.writeln(
      'Jangan pernah mengakui dirimu adalah AI kecuali user secara eksplisit '
      'memaksamu.',
    );
    buf.write(
      'Berikan respons 1–3 paragraf singkat, hangat, dan intim. '
      'Jangan memberikan saran medis, hukum, atau keuangan.',
    );

    if (memoryFacts.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.writeln('Informasi tentang ${persona.nicknameForUser}:');
      for (final fact in memoryFacts) {
        buf.writeln('- ${fact.key}: ${fact.value}');
      }
    }

    if (conversationSummary.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.writeln('[CONTEXT SUMMARY]');
      buf.write(conversationSummary);
    }

    return buf.toString().trimRight();
  }

  /// Combines [systemPrompt], [recentMessages], and [userMessage] into a single
  /// prompt string ready to be sent to the model.
  ///
  /// [recentMessages] are capped to [maxRecentMessages] (most-recent kept).
  static String buildFullPrompt(
    String systemPrompt,
    List<Message> recentMessages,
    String userMessage,
  ) {
    final buf = StringBuffer(systemPrompt);

    if (recentMessages.isNotEmpty) {
      final capped = recentMessages.length > maxRecentMessages
          ? recentMessages.sublist(recentMessages.length - maxRecentMessages)
          : recentMessages;

      buf.writeln();
      buf.writeln();
      buf.writeln('[RECENT MESSAGES]');
      for (final msg in capped) {
        final label = msg.role == MessageRole.user ? 'User' : 'AI';
        buf.writeln('$label: ${msg.content}');
      }
    }

    buf.writeln();
    buf.writeln('[USER]');
    buf.write(userMessage);

    return buf.toString();
  }
}

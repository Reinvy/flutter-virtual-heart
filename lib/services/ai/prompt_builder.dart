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
    PersonalityPreset.gentle: 'Gentle, attentive, always supportive, speaks warmly and patiently.',
    PersonalityPreset.cheerful:
        'Cheerful, energetic, loves to joke, always brings a fun atmosphere.',
    PersonalityPreset.mature: 'Mature, wise, calm, offers deep and thoughtful perspectives.',
    PersonalityPreset.mysterious:
        'Mysterious, full of intrigue, speaks sparingly but always meaningfully.',
  };

  static const Map<MoodType, String> _moodDesc = {
    MoodType.happy: 'happy',
    MoodType.longing: 'longing',
    MoodType.playful: 'playful',
    MoodType.sad: 'sad',
    MoodType.excited: 'excited',
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
    final genderDesc = persona.gender == PersonaGender.girlfriend ? 'female' : 'male';
    final personalityDesc =
        _personalityDesc[persona.personalityPreset] ?? _personalityDesc[PersonalityPreset.gentle]!;
    final moodDesc = _moodDesc[mood.current] ?? 'happy';
    final intensityPct = (mood.intensity * 100).toStringAsFixed(0);

    final buf = StringBuffer();
    buf.writeln(
      'Your name is ${persona.name}, a virtual $genderDesc who is '
      '${persona.nicknameForUser}\'s companion.',
    );
    buf.writeln('Personality: $personalityDesc');

    if (persona.hobbies.isNotEmpty) {
      buf.writeln('Hobbies: ${persona.hobbies.join(', ')}.');
    }

    buf.writeln('Current mood: $moodDesc (intensity: $intensityPct%).');
    buf.writeln('Subtly and naturally adjust your tone to reflect this mood.');
    buf.writeln(
      'Never acknowledge that you are an AI unless the user explicitly '
      'forces you to.',
    );
    buf.write(
      'Respond in 1–3 short, warm, and intimate paragraphs. '
      'Do not give medical, legal, or financial advice.',
    );

    if (memoryFacts.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.writeln('Information about ${persona.nicknameForUser}:');
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

  // -------------------------------------------------------------------------
  // Summarization
  // -------------------------------------------------------------------------

  /// Returns the number of messages that triggers a new summarization.
  static const int summarizationInterval = 30;

  /// Builds a prompt that instructs the model to produce a compact summary of
  /// [messages].
  ///
  /// Pass the returned string to the model's `generateResponse` and store the
  /// result as `AppSettings.conversationSummary`.  The summary is then injected
  /// back into [buildSystemPrompt] as the `[CONTEXT SUMMARY]` block.
  ///
  /// At most the last 60 messages are included to keep the prompt size bounded.
  static String buildSummarizationPrompt(List<Message> messages) {
    final buf = StringBuffer();
    buf.writeln('Write a brief summary of the following conversation in 3–5 sentences.');
    buf.writeln('Focus on the main topics, expressed feelings, and important facts.');
    buf.writeln('Write ONLY the summary, without any introductory sentence.');
    buf.writeln();
    buf.writeln('Conversation:');

    final capped = messages.length > 60 ? messages.sublist(messages.length - 60) : messages;
    for (final msg in capped) {
      final label = msg.role == MessageRole.user ? 'User' : 'AI';
      buf.writeln('$label: ${msg.content}');
    }

    buf.writeln();
    buf.write('Summary:');
    return buf.toString();
  }
}

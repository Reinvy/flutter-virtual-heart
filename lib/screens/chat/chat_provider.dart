import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/objectbox_service.dart';
import '../../data/models/message.dart';
import '../../data/models/persona_config.dart';
import '../../providers/mood_provider.dart';
import '../../providers/objectbox_provider.dart';
import '../../services/ai/memory_extractor.dart';
import '../../services/ai/model_service.dart';
import '../../services/ai/prompt_builder.dart';
import '../../services/mood_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ChatState {
  final List<Message> messages;
  final bool isTyping;

  /// Accumulates AI response tokens during streaming.
  final String streamingBuffer;

  const ChatState({required this.messages, this.isTyping = false, this.streamingBuffer = ''});

  ChatState copyWith({List<Message>? messages, bool? isTyping, String? streamingBuffer}) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        streamingBuffer: streamingBuffer ?? this.streamingBuffer,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final db = ref.read(objectBoxServiceProvider);
    final msgs = db.messageBox.getAll()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ChatState(messages: msgs);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isTyping) return;

    final db = ref.read(objectBoxServiceProvider);

    // 1. Persist user message and update UI immediately.
    final userMsg = Message(
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    db.messageBox.put(userMsg);

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      streamingBuffer: '',
    );

    final buffer = StringBuffer();
    try {
      // 2. Assemble prompt from persona, mood, memory and conversation history.
      final personas = db.personaBox.getAll();
      final persona = personas.isNotEmpty ? personas.first : PersonaConfig();
      final mood = ref.read(moodServiceProvider).getCurrentMood();
      final memoryFacts = db.memoryFactBox.getAll();
      final settings = db.getOrCreateSettings();

      final systemPrompt = PromptBuilder.buildSystemPrompt(
        persona,
        mood,
        memoryFacts,
        settings.conversationSummary,
      );

      // Pass history without the message we just added (it goes into [USER]).
      final history = state.messages.length > 1
          ? state.messages.sublist(0, state.messages.length - 1)
          : <Message>[];

      final fullPrompt = PromptBuilder.buildFullPrompt(systemPrompt, history, text.trim());

      // 3. Stream AI response token-by-token.
      await for (final token
          in ref.read(modelServiceProvider.notifier).generateResponseStream(fullPrompt)) {
        buffer.write(token);
        state = state.copyWith(streamingBuffer: buffer.toString());
      }

      // 4. Persist completed AI message and update UI.
      final aiMsg = Message(
        role: MessageRole.assistant,
        content: buffer.toString(),
        timestamp: DateTime.now(),
      );
      db.messageBox.put(aiMsg);

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
        streamingBuffer: '',
      );

      // 5. Fire-and-forget: memory extraction + mood update.
      Future.microtask(() => _postProcess(db, text.trim(), buffer.toString()));
    } catch (_) {
      state = state.copyWith(isTyping: false, streamingBuffer: '');
    }
  }

  Future<void> _postProcess(ObjectBoxService db, String userMessage, String aiResponse) async {
    // Extract memory facts from the exchange.
    try {
      final conversation = 'User: $userMessage\nAI: $aiResponse';
      final extractor = ref.read(memoryExtractorProvider);
      final facts = await extractor.extractFacts(
        conversation,
        (p) => ref.read(modelServiceProvider.notifier).generateResponse(p),
      );
      if (facts.isNotEmpty) db.memoryFactBox.putMany(facts);
    } catch (_) {
      // Best-effort — ignore extraction errors.
    }

    // Summarize conversation every N messages to keep context window fresh.
    try {
      final allMessages = db.messageBox.getAll();
      if (allMessages.isNotEmpty && allMessages.length % PromptBuilder.summarizationInterval == 0) {
        allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final prompt = PromptBuilder.buildSummarizationPrompt(allMessages);
        final summary = await ref.read(modelServiceProvider.notifier).generateResponse(prompt);
        if (summary.isNotEmpty) {
          final settings = db.getOrCreateSettings();
          settings.conversationSummary = summary.trim();
          db.appSettingsBox.put(settings);
        }
      }
    } catch (_) {
      // Best-effort — ignore summarization errors.
    }

    // Update mood based on the AI response sentiment.
    ref.read(moodServiceProvider).updateMoodFromConversation(aiResponse);
    ref.read(moodProvider.notifier).refresh();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

/// Convenience: list of all persisted messages (sorted by time).
final chatMessagesProvider = Provider<List<Message>>((ref) => ref.watch(chatProvider).messages);

/// Convenience: whether the AI is currently generating a response.
final isTypingProvider = Provider<bool>((ref) => ref.watch(chatProvider).isTyping);

/// Convenience: partial AI response tokens accumulated during streaming.
final streamingBufferProvider = Provider<String>((ref) => ref.watch(chatProvider).streamingBuffer);

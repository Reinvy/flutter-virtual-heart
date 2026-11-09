// Fitur Chat (FR-05..FR-09, FR-11, FR-13) — controller percakapan.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';

import '../../core/errors/app_logger.dart';
import '../../models/memory_fact.dart';
import '../../models/message.dart';
import '../../models/objectbox_provider.dart';
import '../../models/persona_config.dart';
import '../../services/ai/content_safety.dart';
import '../../services/ai/memory_extractor.dart';
import '../../services/ai/model_service.dart';
import '../../services/ai/prompt_builder.dart';
import '../../services/mood_service.dart';
import '../memory/memory_controller.dart';
import '../settings/settings_controller.dart';
import 'chat_models.dart';
import 'mood_provider.dart';

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final db = ref.read(objectBoxServiceProvider);
    final msgs = db.messageBox.getAll()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ChatState(messages: msgs);
  }

  /// Mengirim pesan user → pipeline AI (safety → prompt → streaming → persist)
  /// lalu memicu post-process (memori, ringkasan, mood).
  ///
  /// [isVoice] menandai pesan yang berasal dari transkrip STT (FR-06).
  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    final trimmed = text.trim();
    // FR-05: batas input 2000 karakter (jaring pengaman di sisi controller).
    final content = trimmed.length > 2000 ? trimmed.substring(0, 2000) : trimmed;
    if (content.isEmpty || state.isTyping) return;

    final db = ref.read(objectBoxServiceProvider);
    ref.read(moodServiceProvider).recordInteraction();

    // 1. Persist pesan user + update UI.
    final userMsg = Message(
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isVoice: isVoice,
    );
    db.messageBox.put(userMsg);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      streamingBuffer: '',
    );

    // 1b. Content safety gate (input) — FR-14.
    final inputCheck = ContentSafety.filterInput(content);
    if (inputCheck.isBlocked) {
      final safetyMsg = Message(
        role: MessageRole.assistant,
        content: inputCheck.redirectResponse!,
        timestamp: DateTime.now(),
      );
      db.messageBox.put(safetyMsg);
      state = state.copyWith(
        messages: [...state.messages, safetyMsg],
        isTyping: false,
        streamingBuffer: '',
      );
      return;
    }

    final buffer = StringBuffer();
    try {
      // 2. Susun prompt dari persona, mood, memori, ringkasan & riwayat.
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
        language: settings.language,
      );

      final history = state.messages.length > 1
          ? state.messages.sublist(0, state.messages.length - 1)
          : <Message>[];

      final fullPrompt = PromptBuilder.buildFullPrompt(systemPrompt, history, content);

      // 2b. Tandai fakta memori yang dipakai sebagai konteks (FR-11).
      _stampReferencedFacts(db.memoryFactBox, memoryFacts);

      // 3. Stream token AI.
      await for (final token
          in ref.read(modelServiceProvider.notifier).generateResponseStream(fullPrompt)) {
        buffer.write(token);
        state = state.copyWith(streamingBuffer: buffer.toString());
      }

      // 4a. Content safety gate (output) — FR-14.
      final outputCheck = ContentSafety.validateOutput(buffer.toString());
      final finalContent = outputCheck.isBlocked
          ? outputCheck.redirectResponse!
          : buffer.toString();

      // 4b. Persist pesan AI + update UI.
      final aiMsg = Message(
        role: MessageRole.assistant,
        content: finalContent,
        timestamp: DateTime.now(),
        mood: mood.current.name,
      );
      db.messageBox.put(aiMsg);
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
        streamingBuffer: '',
      );

      // 5. Post-process fire-and-forget: memori (FR-11), ringkasan (FR-13),
      //    mood (FR-09). Best-effort — kegagalan tidak memblokir chat.
      Future.microtask(() => _postProcess(content, finalContent));
    } catch (e) {
      AppLogger.error('Chat send failed', e);
      state = state.copyWith(isTyping: false, streamingBuffer: '');
    }
  }

  /// Pipeline pasca-respons: ekstraksi memori, ringkasan, dan update mood.
  Future<void> _postProcess(String userMessage, String aiResponse) async {
    final db = ref.read(objectBoxServiceProvider);

    // Ekstraksi fakta memori (FR-11): gabungkan dengan fakta lama bila key-nya
    // sama, bukan menumpuk duplikat.
    try {
      final conversation = 'User: $userMessage\nAI: $aiResponse';
      final extractor = ref.read(memoryExtractorProvider);
      final facts = await extractor.extractFacts(
        conversation,
        (p) => ref.read(modelServiceProvider.notifier).generateResponse(p),
      );
      if (facts.isNotEmpty) {
        final existing = {
          for (final fact in db.memoryFactBox.getAll()) fact.key.toLowerCase(): fact,
        };
        for (final fact in facts) {
          final match = existing[fact.key.toLowerCase()];
          if (match != null) {
            match
              ..value = fact.value
              ..category = fact.category
              ..sourceSnippet = userMessage;
            db.memoryFactBox.put(match);
          } else {
            fact.sourceSnippet = userMessage;
            db.memoryFactBox.put(fact);
          }
        }
        ref.invalidate(memoryFactsProvider);
      }
    } catch (e) {
      AppLogger.debug('Memory extraction skipped', e);
    }

    // Ringkasan percakapan setiap N pesan (FR-13).
    try {
      final allMessages = db.messageBox.getAll();
      if (allMessages.isNotEmpty &&
          allMessages.length % PromptBuilder.summarizationInterval == 0) {
        allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final prompt = PromptBuilder.buildSummarizationPrompt(allMessages);
        final summary = await ref.read(modelServiceProvider.notifier).generateResponse(prompt);
        if (summary.isNotEmpty) {
          ref.read(appSettingsProvider.notifier).setConversationSummary(summary.trim());
        }
      }
    } catch (e) {
      AppLogger.debug('Summarization skipped', e);
    }

    // Update mood dari sentimen respons AI (FR-09).
    ref.read(moodServiceProvider).updateMoodFromConversation(aiResponse);
    ref.read(moodProvider.notifier).refresh();
  }

  /// Menandai `lastReferencedAt` untuk fakta yang ikut masuk ke prompt.
  void _stampReferencedFacts(Box<MemoryFact> box, List<MemoryFact> facts) {
    if (facts.isEmpty) return;
    final now = DateTime.now();
    for (final fact in facts) {
      fact.lastReferencedAt = now;
    }
    box.putMany(facts);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

// Fitur Chat (FR-05..FR-09, FR-11, FR-13) — controller percakapan.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';

import '../../core/errors/app_logger.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/memory_fact.dart';
import '../../models/message.dart';
import 'package:virtual_heart/services/database/objectbox_provider.dart';
import '../../models/persona_config.dart';
import '../../services/ai/content_safety.dart';
import '../../services/ai/memory_extractor.dart';
import '../../services/ai/memory_fact_merger.dart';
import '../../services/ai/model_service.dart';
import '../../services/ai/prompt_builder.dart';
import '../../services/mood_service.dart';
import '../memory/memory_controller.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'chat_models.dart';
import 'mood_provider.dart';

class ChatNotifier extends Notifier<ChatState> {
  /// Generasi yang sedang berjalan (ditunggu oleh [cancelGeneration]).
  Future<void>? _inFlight;
  bool _cancelling = false;

  /// Antrean post-process (memori + ringkasan) agar tidak tumpang tindih.
  Future<void> _postProcessQueue = Future.value();

  /// `true` setelah pengguna meminta berhenti / provider di-dispose.
  bool _cancelRequested = false;

  @override
  ChatState build() {
    ref.onDispose(() => _cancelRequested = true);
    final db = ref.read(objectBoxServiceProvider);
    final msgs = db.messageBox.getAll()..sort(compareMessages);
    return ChatState(messages: msgs);
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Mengirim pesan user → pipeline AI (safety → prompt → streaming → persist)
  /// lalu memicu post-process (memori, ringkasan).
  ///
  /// [isVoice] menandai pesan yang berasal dari transkrip STT (FR-06).
  Future<void> sendMessage(String text, {bool isVoice = false}) {
    if (!ref.mounted || state.isTyping || _cancelling) return Future.value();
    final trimmed = text.trim();
    // FR-05: batas input 2000 karakter tanpa memotong pasangan surrogate.
    final content = PromptBuilder.truncate(
      trimmed,
      PromptBuilder.maxLatestUserChars,
    );
    if (content.isEmpty) return Future.value();

    late final Future<void> future;
    future = _send(content, isVoice: isVoice).whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  /// Menghentikan generasi yang sedang berjalan dan menunggu tulis DB selesai.
  ///
  /// Dipakai tombol stop dan sebelum aksi destruktif (reset/hapus).
  Future<void> cancelGeneration() async {
    _cancelling = true;
    _cancelRequested = true;
    try {
      try {
        await ref.read(modelServiceProvider.notifier).stopGeneration();
      } catch (e) {
        AppLogger.debug('Stop generation failed', e);
      }
      final flight = _inFlight;
      if (flight != null) {
        try {
          await flight;
        } catch (e) {
          AppLogger.debug('Cancel await skipped', e);
        }
      }
      try {
        await _postProcessQueue;
      } catch (e) {
        AppLogger.debug('Cancel post-process skipped', e);
      }
    } finally {
      _cancelling = false;
    }
  }

  /// Menutup banner error tanpa mengubah pesan.
  void clearError() {
    if (!ref.mounted) return;
    state = state.copyWith(clearError: true);
  }

  /// Mengulang jawaban untuk pesan user terakhir tanpa menyimpan pesan baru.
  Future<void> retryLastResponse() {
    if (!ref.mounted || state.isTyping || _cancelling) return Future.value();
    final messages = state.messages;
    final lastUserIndex = messages.lastIndexWhere((m) => m.role == MessageRole.user);
    if (lastUserIndex < 0) return Future.value();

    final db = ref.read(objectBoxServiceProvider);
    final trailingIds = <int>[];
    for (var i = lastUserIndex + 1; i < messages.length; i++) {
      final id = messages[i].id;
      if (id != 0) trailingIds.add(id);
    }
    if (trailingIds.isNotEmpty) {
      db.messageBox.removeMany(trailingIds);
    }
    final retained = messages.sublist(0, lastUserIndex + 1);
    if (retained.length != messages.length) {
      state = state.copyWith(messages: retained, clearError: true);
    }

    final last = retained[lastUserIndex];
    final history = retained
        .sublist(0, lastUserIndex)
        .where((m) => !m.isBlocked)
        .toList();
    _cancelRequested = false;
    late final Future<void> future;
    future = _generateReply(
      latestUserInput: last.content,
      history: history,
      strings: ref.read(appStringsProvider),
    ).whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }
  // -------------------------------------------------------------------------
  // Send / generate
  // -------------------------------------------------------------------------

  Future<void> _send(String content, {required bool isVoice}) async {
    if (!ref.mounted || state.isTyping) return;
    _cancelRequested = false;
    final db = ref.read(objectBoxServiceProvider);
    final strings = ref.read(appStringsProvider);
    ref.read(moodServiceProvider).recordInteraction();

    // 1. Gate input SEBELUM dipersist: teks terblokir tidak boleh masuk prompt
    //    atau ringkasan percakapan berikutnya (FR-14).
    final inputCheck = ContentSafety.filterInput(content);
    final userMsg = Message(
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isVoice: isVoice,
      isBlocked: inputCheck.isBlocked,
    );
    db.messageBox.put(userMsg);
    if (!ref.mounted) return;
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: !inputCheck.isBlocked,
      streamingBuffer: '',
      clearError: true,
    );

    if (inputCheck.isBlocked) {
      final mood = ref.read(moodServiceProvider).getCurrentMood();
      final safetyMsg = Message(
        role: MessageRole.assistant,
        content: _deflection(inputCheck.redirect!, strings),
        timestamp: DateTime.now(),
        mood: mood.current.name,
      );
      db.messageBox.put(safetyMsg);
      if (!ref.mounted) return;
      state = state.copyWith(
        messages: [...state.messages, safetyMsg],
        isTyping: false,
        streamingBuffer: '',
      );
      return;
    }

    final history = state.messages
        .where((m) => !m.isBlocked && m.id != userMsg.id)
        .toList();
    await _generateReply(
      latestUserInput: content,
      history: history,
      strings: strings,
    );
  }

  Future<void> _generateReply({
    required String latestUserInput,
    required List<Message> history,
    required AppStrings strings,
  }) async {
    if (!ref.mounted) return;
    state = state.copyWith(isTyping: true, streamingBuffer: '', clearError: true);

    final db = ref.read(objectBoxServiceProvider);
    final model = ref.read(modelServiceProvider.notifier);
    final buffer = StringBuffer();
    final usedFacts = <MemoryFact>[];
    SafetyRedirect? blockedRedirect;
    ChatErrorKind? failure;

    try {
      final personas = db.personaBox.getAll();
      final persona = personas.isNotEmpty ? personas.first : PersonaConfig();
      final settings = db.getOrCreateSettings();
      final mood = ref.read(moodServiceProvider).getCurrentMood();
      final allFacts = db.memoryFactBox.getAll();
      usedFacts.addAll(PromptBuilder.selectMemoryFacts(allFacts));

      final systemPrompt = PromptBuilder.buildSystemPrompt(
        persona,
        mood,
        usedFacts,
        settings.conversationSummary,
        language: settings.language,
      );
      final fullPrompt = PromptBuilder.buildFullPrompt(systemPrompt, history, latestUserInput);

      // Holdback 64 karakter: token terakhir tidak langsung tampil sehingga
      // pola terlarang sempat terdeteksi sebelum terlihat pengguna.
      const holdback = 64;
      await for (final token in model.generateResponseStream(
        fullPrompt,
        isCancelled: () => _cancelRequested || !ref.mounted,
      )) {
        if (_cancelRequested || !ref.mounted) break;
        buffer.write(token);
        final full = buffer.toString();
        final tail = full.length > 256
            ? full.substring(full.length - 256)
            : full;
        final check = ContentSafety.validateOutput(tail);
        if (check.isBlocked) {
          blockedRedirect = check.redirect!;
          await model.stopGeneration();
          break;
        }
        final visible =
            full.length <= holdback ? '' : full.substring(0, full.length - holdback);
        if (_cancelRequested || !ref.mounted) break;
        state = state.copyWith(streamingBuffer: visible);
      }
    } on ContextLimitReachedException {
      failure = ChatErrorKind.contextLimit;
    } catch (e) {
      AppLogger.error('Chat generation failed', e);
      failure = _classifyGenerationError(e);
    }

    if (!ref.mounted) return;

    final raw = buffer.toString();

    // Generasi gagal / dibatalkan sebelum selesai.
    if (failure != null) {
      final partial = raw.trim();
      if (partial.isNotEmpty && blockedRedirect == null) {
        final aiMsg = Message(
          role: MessageRole.assistant,
          content: partial,
          timestamp: DateTime.now(),
        );
        db.messageBox.put(aiMsg);
        if (!ref.mounted) return;
        state = state.copyWith(
          messages: [...state.messages, aiMsg],
          isTyping: false,
          streamingBuffer: '',
          error: ChatError(failure),
        );
      } else {
        state = state.copyWith(
          isTyping: false,
          streamingBuffer: '',
          error: ChatError(failure, canRetry: true),
        );
      }
      return;
    }

    // Gate output terakhir untuk sisa token yang masih di holdback.
    final outputCheck = ContentSafety.validateOutput(raw);
    final redirect = blockedRedirect ?? (outputCheck.isBlocked ? outputCheck.redirect : null);
    final finalContent = redirect != null ? _deflection(redirect, strings) : raw.trim();

    if (finalContent.isEmpty) {
      state = state.copyWith(
        isTyping: false,
        streamingBuffer: '',
        error: ChatError(
          _cancelRequested ? ChatErrorKind.interrupted : ChatErrorKind.generationFailed,
          canRetry: true,
        ),
      );
      return;
    }

    final moodService = ref.read(moodServiceProvider);
    final updatedMood = redirect == null
        ? moodService.updateMoodFromConversation(latestUserInput, finalContent)
        : moodService.getCurrentMood();

    final aiMsg = Message(
      role: MessageRole.assistant,
      content: finalContent,
      timestamp: DateTime.now(),
      mood: updatedMood.current.name,
    );
    db.messageBox.put(aiMsg);
    if (!ref.mounted) return;
    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isTyping: false,
      streamingBuffer: '',
      error: _cancelRequested ? const ChatError(ChatErrorKind.interrupted) : null,
    );
    ref.read(moodProvider.notifier).refresh();

    // Deflection keamanan / jawaban terhenti tidak boleh mengotori memori,
    // ringkasan, maupun penanda fakta yang dipakai.
    if (redirect != null || _cancelRequested) return;

    _stampReferencedFacts(db.memoryFactBox, usedFacts);
    _enqueuePostProcess(latestUserInput, finalContent);
  }

  // -------------------------------------------------------------------------
  // Post-processing (memori + ringkasan)
  // -------------------------------------------------------------------------

  void _enqueuePostProcess(String user, String ai) {
    _postProcessQueue = _postProcessQueue
        .then((_) => _postProcess(user, ai))
        .catchError((Object e) => AppLogger.debug('Post-process skipped', e));
  }

  /// Pipeline pasca-respons: ekstraksi memori lalu ringkasan percakapan.
  Future<void> _postProcess(String userMessage, String aiResponse) async {
    if (_cancelRequested || !ref.mounted) return;
    final db = ref.read(objectBoxServiceProvider);

    // Ekstraksi fakta memori (FR-11).
    try {
      final conversation = 'User: $userMessage\nAI: $aiResponse';
      final facts = await ref.read(memoryExtractorProvider).extractFacts(
        conversation,
        (p) => ref.read(modelServiceProvider.notifier).generateResponse(p),
      );
      if (_cancelRequested || !ref.mounted) return;
      if (facts.isNotEmpty) {
        final result = mergeFacts(
          existing: db.memoryFactBox.getAll(),
          incoming: facts,
          sourceSnippet: userMessage,
        );
        if (result.deleteIds.isNotEmpty) db.memoryFactBox.removeMany(result.deleteIds);
        if (result.upserts.isNotEmpty) db.memoryFactBox.putMany(result.upserts);
        if (ref.mounted) ref.invalidate(memoryFactsProvider);
      }
    } catch (e) {
      AppLogger.debug('Memory extraction skipped', e);
    }

    // Ringkasan percakapan setiap [PromptBuilder.summarizationInterval] pesan
    // baru yang belum diringkas (FR-13).
    if (_cancelRequested || !ref.mounted) return;
    try {
      final settings = db.getOrCreateSettings();
      final allMessages = db.messageBox.getAll()..sort(compareMessages);
      final visible = allMessages.where((m) => !m.isBlocked).toList();
      if (visible.isNotEmpty &&
          visible.length - settings.summaryMessageCount >=
              PromptBuilder.summarizationInterval) {
        final prompt = PromptBuilder.buildSummarizationPrompt(
          visible,
          language: settings.language,
        );
        if (_cancelRequested || !ref.mounted) return;
        final summary =
            await ref.read(modelServiceProvider.notifier).generateResponse(prompt);
        if (_cancelRequested || !ref.mounted) return;
        final cleaned = _cleanSummary(summary);
        if (cleaned.isNotEmpty) {
          final notifier = ref.read(appSettingsProvider.notifier);
          notifier.save(
            ref.read(appSettingsProvider).copyWith(
              conversationSummary: cleaned,
              summaryMessageCount: visible.length,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.debug('Summarization skipped', e);
    }
  }

  /// Menandai `lastReferencedAt` hanya untuk fakta yang benar-benar dipakai,
  /// dan hanya setelah generasi sukses.
  static void _stampReferencedFacts(Box<MemoryFact> box, List<MemoryFact> facts) {
    if (facts.isEmpty) return;
    final now = DateTime.now();
    for (final fact in facts) {
      fact.lastReferencedAt = now;
    }
    box.putMany(facts);
  }

  static String _cleanSummary(String raw) {
    var text = raw.trim();
    final lower = text.toLowerCase();
    if (lower.startsWith('summary:')) {
      text = text.substring('summary:'.length).trim();
    } else if (lower.startsWith('ringkasan:')) {
      text = text.substring('ringkasan:'.length).trim();
    }
    return PromptBuilder.truncate(text, PromptBuilder.maxStoredSummaryChars);
  }

  static ChatErrorKind _classifyGenerationError(Object error) {
    if (error is ContextLimitReachedException) return ChatErrorKind.contextLimit;
    if (error is ModelException) {
      return error.kind == ModelErrorKind.engine
          ? ChatErrorKind.modelUnavailable
          : ChatErrorKind.generationFailed;
    }
    if (error is StateError) return ChatErrorKind.modelUnavailable;
    return ChatErrorKind.generationFailed;
  }

  /// Memetakan [SafetyRedirect] ke teks terlokalisasi.
  static String _deflection(SafetyRedirect redirect, AppStrings strings) => switch (redirect) {
    SafetyRedirect.explicitSexual => strings.safetyExplicit,
    SafetyRedirect.explicitSexualOutput => strings.safetyExplicitOutput,
    SafetyRedirect.selfHarm => strings.safetySelfHarm,
    SafetyRedirect.professionalAdvice => strings.safetyProfessionalAdvice,
    SafetyRedirect.hateSpeech => strings.safetyHateSpeech,
    SafetyRedirect.violence => strings.safetyViolence,
    SafetyRedirect.personaBreak => strings.safetyPersonaBreak,
  };
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class PendingChatDraftNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setDraft(String? draft) => state = draft;

  String? consume() {
    final current = state;
    if (current != null) state = null;
    return current;
  }
}

final pendingChatDraftProvider =
    NotifierProvider<PendingChatDraftNotifier, String?>(
      PendingChatDraftNotifier.new,
    );

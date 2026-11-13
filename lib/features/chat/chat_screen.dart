// Fitur Chat (FR-05..FR-10) — layar percakapan editorial.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/design/components/app_icon_button.dart';
import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/app_sheet.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/app_settings.dart';
import '../../models/message.dart';
import '../../models/mood_state.dart';
import '../../models/persona_config.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';
import '../persona/avatar_catalog.dart';
import '../persona/persona_controller.dart';
import '../persona/persona_edit_sheet.dart';
import '../persona/persona_profile_sheet.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'chat_controller.dart';
import 'chat_models.dart';
import 'mood_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/input_bar.dart';
import 'widgets/mood_indicator.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _ttsService = TtsService();
  final _sttService = SttService();
  final _inputTextController = TextEditingController();

  int _speakingMessageId = -1;
  bool _isListening = false;
  String? _voiceDraft;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _inputTextController.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumePendingDraft();
    });
  }

  @override
  void dispose() {
    _inputTextController.removeListener(_onInputChanged);
    _scrollController.dispose();
    _inputTextController.dispose();
    _ttsService.stop();
    _sttService.cancel();
    super.dispose();
  }

  void _consumePendingDraft() {
    final draft = ref.read(pendingChatDraftProvider.notifier).consume();
    if (draft == null || draft.isEmpty) return;
    _inputTextController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  /// Dikte dianggap pesan suara hanya selama teksnya tidak diubah pengguna.
  void _onInputChanged() {
    final draft = _voiceDraft;
    if (draft == null) return;
    if (_inputTextController.text != draft) _voiceDraft = null;
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels < position.maxScrollExtent - 120) return;
      if (animate) {
        _scrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position.maxScrollExtent);
      }
    });
  }

  void _scrollToLatestOnOpen() {
    if (_didInitialScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _didInitialScroll = true;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final persona = ref.watch(personaProvider);
    final chatState = ref.watch(chatProvider);
    final currentMood = ref.watch(moodProvider).current;
    final settings = ref.watch(appSettingsProvider);

    ref.listen(pendingChatDraftProvider, (prev, next) {
      if (next != null && next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _consumePendingDraft();
        });
      }
    });

    ref.listen(activeShellTabProvider, (prev, next) {
      if (prev == 1 && next != 1) {
        _ttsService.stop();
        _sttService.cancel();
        if (mounted) {
          setState(() {
            _isListening = false;
            _speakingMessageId = -1;
          });
        }
      }
    });

    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      } else if (prev?.streamingBuffer != next.streamingBuffer) {
        _scrollToBottom(animate: false);
      }

      if (!next.isTyping &&
          prev?.isTyping == true &&
          next.messages.isNotEmpty) {
        final last = next.messages.last;
        if (last.role == MessageRole.assistant) {
          final currentSettings = ref.read(appSettingsProvider);
          if (mounted &&
              ref.read(activeShellTabProvider) == 1 &&
              (ModalRoute.of(context)?.isCurrent ?? false) &&
              currentSettings.ttsEnabled &&
              currentSettings.ttsAutoPlay) {
            _speakMessage(last, persona);
          }
        }
      }
    });

    if (chatState.messages.isNotEmpty) _scrollToLatestOnOpen();

    return AppScaffold(
      safeArea: false,
      appBar: _buildAppBar(strings, persona, currentMood),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(
              strings,
              chatState.messages,
              chatState.isTyping,
              chatState.streamingBuffer,
              persona,
              settings.ttsEnabled,
            ),
          ),
          if (chatState.error != null)
            _ChatErrorBanner(
              message: _chatErrorText(strings, chatState.error!.kind),
              retryLabel: chatState.error!.canRetry ? strings.chatRetry : null,
              dismissLabel: strings.chatDismiss,
              onRetry: () =>
                  ref.read(chatProvider.notifier).retryLastResponse(),
              onDismiss: () => ref.read(chatProvider.notifier).clearError(),
            ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: InputBar(
                enabled: !chatState.isTyping,
                isTyping: chatState.isTyping,
                isListening: _isListening,
                controller: _inputTextController,
                onMicTap: _handleMicTap,
                onStop: () =>
                    ref.read(chatProvider.notifier).cancelGeneration(),
                onSend: (text) {
                  HapticFeedback.lightImpact();
                  final isVoice = _voiceDraft != null;
                  _voiceDraft = null;
                  ref
                      .read(chatProvider.notifier)
                      .sendMessage(text, isVoice: isVoice);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _chatErrorText(AppStrings strings, ChatErrorKind kind) =>
      switch (kind) {
        ChatErrorKind.modelUnavailable => strings.chatModelUnavailable,
        ChatErrorKind.contextLimit => strings.chatContextLimit,
        ChatErrorKind.generationFailed => strings.chatGenerationFailed,
        ChatErrorKind.interrupted => strings.chatInterrupted,
      };

  PreferredSizeWidget _buildAppBar(
    AppStrings strings,
    PersonaConfig? persona,
    MoodType currentMood,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: scheme.surface,
      elevation: 0,
      titleSpacing: 0,
      leadingWidth: 64,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: scheme.outlineVariant,
        ),
      ),
      leading: Semantics(
        button: true,
        label: strings.chatOpenProfile,
        child: InkWell(
          onTap: () => _openPersonaProfile(persona),
          child: Center(
            child: personaAvatar(
              context,
              name: persona?.name,
              avatarId: persona?.avatarId,
              size: 40,
            ),
          ),
        ),
      ),
      title: InkWell(
        onTap: () => _openPersonaProfile(persona),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              persona?.name ?? strings.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.personaName(
                context,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            const MoodIndicator(),
          ],
        ),
      ),
      actions: [
        AppIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: strings.chatOpenProfile,
          onPressed: () => _openPersonaProfile(persona),
        ),
        const SizedBox(width: AppSizes.spaceXs),
      ],
    );
  }

  /// Membuka profil persona; jika pengguna memilih Edit, buka form edit.
  Future<void> _openPersonaProfile(PersonaConfig? persona) async {
    final edit = await showPersonaProfileSheet(context, persona);
    if (edit == true && mounted) {
      await showAppSheet<void>(context, child: const PersonaEditSheet());
    }
  }

  Future<void> _speakMessage(Message message, PersonaConfig? persona) async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.ttsEnabled) return;

    if (_speakingMessageId == message.id) {
      await _ttsService.stop();
      if (!mounted) return;
      setState(() => _speakingMessageId = -1);
      return;
    }

    final ready = await _ttsService.ensureReady(
      backend: settings.ttsBackend,
      model: settings.ttsModel,
    );
    if (!mounted) return;
    if (!ready) {
      _showSnack(ref.read(appStringsProvider).chatTtsUnavailable);
      return;
    }

    setState(() => _speakingMessageId = message.id);
    final ok = await _ttsService.speak(
      message.content,
      backend: settings.ttsBackend,
      model: settings.ttsModel,
      gender: persona?.gender,
      languageCode: _speechLanguageCode(settings.language),
      onDone: () {
        if (mounted) setState(() => _speakingMessageId = -1);
      },
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _speakingMessageId = -1);
      _showSnack(ref.read(appStringsProvider).chatTtsUnavailable);
    }
  }

  Future<void> _handleMicTap() async {
    final strings = ref.read(appStringsProvider);
    final settings = ref.read(appSettingsProvider);

    if (_isListening) {
      String transcript;
      try {
        transcript = await _sttService.stopListening(
          backend: settings.sttBackend,
          languageCode: _speechLanguageCode(settings.language),
        );
      } catch (_) {
        transcript = '';
      }
      if (!mounted) return;
      setState(() => _isListening = false);
      if (transcript.trim().isNotEmpty) {
        HapticFeedback.lightImpact();
        _insertTranscript(transcript.trim());
      }
      return;
    }

    await _ttsService.stop();
    if (!mounted) return;
    setState(() => _speakingMessageId = -1);

    final result = await _sttService.startListening(
      backend: settings.sttBackend,
      languageCode: _speechLanguageCode(settings.language),
    );
    if (!mounted) return;

    switch (result) {
      case SttStartResult.started:
        HapticFeedback.lightImpact();
        setState(() => _isListening = true);
      case SttStartResult.permissionDenied:
        _showSnack(
          strings.chatMicPermission,
          action: SnackBarAction(
            label: strings.chatMicOpenSettings,
            onPressed: openAppSettings,
          ),
        );
      case SttStartResult.unavailable:
        _showSnack(strings.chatSttUnavailable);
      case SttStartResult.busy:
        break;
    }
  }

  void _insertTranscript(String transcript) {
    final value = _inputTextController.value;
    final text = value.text;
    final start = value.selection.isValid ? value.selection.start : text.length;
    final end = value.selection.isValid ? value.selection.end : text.length;
    final needsSpace = start > 0 && !text.substring(0, start).endsWith(' ');
    final insert = needsSpace ? ' $transcript' : transcript;
    final newText = text.replaceRange(start, end, insert);

    _voiceDraft = newText;
    _inputTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String _speechLanguageCode(AppLanguage language) =>
      language == AppLanguage.english ? 'en-US' : 'id-ID';

  Widget _buildMessageList(
    AppStrings strings,
    List<Message> messages,
    bool isTyping,
    String streamingBuffer,
    PersonaConfig? persona,
    bool ttsEnabled,
  ) {
    final itemCount = messages.length + (isTyping ? 1 : 0);

    if (itemCount == 0) {
      return _EmptyChat(
        strings: strings,
        personaName: persona?.name,
        persona: persona,
      );
    }

    return SelectionArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceSm),
            itemCount: itemCount,
            itemBuilder: (ctx, i) {
              if (i == messages.length) {
                if (streamingBuffer.isNotEmpty) {
                  final streamingMsg = Message(
                    role: MessageRole.assistant,
                    content: streamingBuffer,
                    timestamp: DateTime.now(),
                  );
                  return ChatBubble(
                    key: const ValueKey('streaming'),
                    message: streamingMsg,
                    persona: persona,
                    isStreaming: true,
                  );
                }
                return TypingIndicator(persona: persona);
              }

              return ChatBubble(
                key: ValueKey(messages[i].id),
                message: messages[i],
                persona: persona,
                speakerLabel: _speakingMessageId == messages[i].id
                    ? strings.chatStopSpeaking
                    : strings.chatSpeak,
                onSpeak: ttsEnabled && messages[i].role == MessageRole.assistant
                    ? () => _speakMessage(messages[i], persona)
                    : null,
                isSpeaking: _speakingMessageId == messages[i].id,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatErrorBanner extends StatelessWidget {
  const _ChatErrorBanner({
    required this.message,
    required this.retryLabel,
    required this.dismissLabel,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final String? retryLabel;
  final String dismissLabel;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSizes.spaceMd,
        0,
        AppSizes.spaceMd,
        AppSizes.spaceXs,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spaceSm,
        AppSizes.spaceXs,
        AppSizes.spaceXxs,
        AppSizes.spaceXs,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: scheme.error, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: AppSizes.spaceXs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium(color: scheme.onErrorContainer),
            ),
          ),
          if (retryLabel != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryLabel!,
                style: AppTextStyles.button(color: scheme.error),
              ),
            ),
          AppIconButton(
            icon: Icons.close_rounded,
            tooltip: dismissLabel,
            color: scheme.onErrorContainer,
            size: 20,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.strings, this.personaName, this.persona});

  final AppStrings strings;
  final String? personaName;
  final PersonaConfig? persona;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final greeting = fillPlaceholders(strings.chatEmptyGreeting, {
      'name': personaName ?? strings.chatFallbackName,
    });

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pageGutter,
          vertical: AppSizes.spaceLg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  personaAvatar(
                    context,
                    name: personaName,
                    avatarId: persona?.avatarId,
                    size: 56,
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  Text(
                    greeting,
                    style: AppTextStyles.displaySmall(
                      context,
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.chatEmptyBody,
                    style: AppTextStyles.bodyLarge(
                      color: AppColors.textSecondaryFor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  SizedBox(
                    width: 64,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Fitur Chat (FR-05..FR-10) — layar utama chat.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/design/components/app_icon_button.dart';
import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/app_sheet.dart';
import '../../core/design/components/bloom_mark.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
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
  // Teks input tepat setelah dikte; dipakai untuk menandai pesan berikutnya
  // sebagai pesan suara (FR-06) — batal bila pengguna mengedit teksnya.
  String? _voiceDraft;
  bool _sparkleShown = false;
  bool _showSparkle = false;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _inputTextController.addListener(_onInputChanged);
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

  /// Dikte dianggap pesan suara hanya selama teksnya tidak diubah pengguna.
  void _onInputChanged() {
    final draft = _voiceDraft;
    if (draft == null) return;
    if (_inputTextController.text != draft) _voiceDraft = null;
  }

  /// Menggulir ke pesan terbaru hanya bila pengguna memang sedang di bawah
  /// (agar membaca riwayat tidak terlempar tiap token).
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

  /// Lompat ke pesan terbaru sekali saat riwayat pertama kali dimuat.
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
          if (!_sparkleShown) {
            setState(() {
              _sparkleShown = true;
              _showSparkle = true;
            });
            Future.delayed(const Duration(milliseconds: 1800), () {
              if (mounted) setState(() => _showSparkle = false);
            });
          }
          final settings = ref.read(appSettingsProvider);
          if (mounted &&
              (ModalRoute.of(context)?.isCurrent ?? false) &&
              settings.ttsEnabled &&
              settings.ttsAutoPlay) {
            _speakMessage(last, persona);
          }
        }
      }
    });

    if (chatState.messages.isNotEmpty) _scrollToLatestOnOpen();

    return AppScaffold(
      safeArea: false,
      appBar: _buildAppBar(strings, persona, currentMood),
      body: Stack(
        children: [
          Column(
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
                  retryLabel: chatState.error!.canRetry
                      ? strings.chatRetry
                      : null,
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
          if (_showSparkle)
            const IgnorePointer(
              child: SizedBox.expand(child: _SparkleOverlay()),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leadingWidth: 68,
      toolbarHeight: 68,
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
              name: persona?.name,
              avatarId: persona?.avatarId,
              size: AppSizes.avatarNav,
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
              style: AppTextStyles.personaName(color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            const MoodIndicator(),
          ],
        ),
      ),
      actions: [
        AppIconButton(
          icon: Icons.bookmark_outline_rounded,
          tooltip: strings.memoryTitle,
          onPressed: () => _leaveChat(AppRoutes.memory),
        ),
        AppIconButton(
          icon: Icons.settings_outlined,
          tooltip: strings.settingsTitle,
          onPressed: () => _leaveChat(AppRoutes.settings),
        ),
        const SizedBox(width: AppSizes.spaceXxs),
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

  /// Meninggalkan chat: hentikan audio yang sedang berjalan lebih dulu.
  Future<void> _leaveChat(String route) async {
    await _ttsService.stop();
    await _sttService.cancel();
    if (mounted) setState(() => _isListening = false);
    if (mounted) await context.push(route);
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

    // Pastikan backend suara siap; jika gagal tampilkan pesan hangat.
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
        // Masukkan transkrip ke posisi kursor (bisa diedit) — FR-06.
        _insertTranscript(transcript.trim());
      }
      return;
    }

    // Hentikan TTS lebih dulu: mikrofon tidak boleh merekam suara AI.
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

  /// Menyisipkan transkrip pada posisi seleksi tanpa menimpa teks yang ada.
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

  /// Kode bahasa untuk TTS/STT mengikuti bahasa AI yang dipilih pengguna.
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
        0,
        AppSizes.spaceXs,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSizes.radiusControl),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
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
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const BloomMark(size: 132, animate: true),
                        personaAvatar(
                          name: personaName,
                          avatarId: persona?.avatarId,
                          size: 64,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  Text(
                    greeting,
                    style: AppTextStyles.displaySmall(color: scheme.onSurface),
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
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 1,
                          color: scheme.outlineVariant,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 12,
                            color: scheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 1,
                          color: scheme.outlineVariant,
                        ),
                      ],
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

class _SparkleOverlay extends StatelessWidget {
  const _SparkleOverlay();

  static const List<List<double>> _configs = [
    [0.10, 0.30, 10, 0],
    [0.28, 0.38, 7, 80],
    [0.50, 0.32, 12, 160],
    [0.68, 0.42, 8, 40],
    [0.82, 0.28, 9, 220],
    [0.22, 0.48, 11, 120],
    [0.73, 0.22, 7, 280],
    [0.40, 0.52, 13, 60],
    [0.60, 0.18, 8, 200],
    [0.14, 0.20, 10, 340],
  ];

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        for (int i = 0; i < _configs.length; i++)
          _SparkleParticle(index: i, screenSize: size),
      ],
    );
  }
}

class _SparkleParticle extends StatelessWidget {
  const _SparkleParticle({required this.index, required this.screenSize});

  final int index;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    final cfg = _SparkleOverlay._configs[index];
    final scheme = Theme.of(context).colorScheme;
    final color = index % 3 == 0
        ? AppColors.goldFor(context)
        : index % 3 == 1
        ? scheme.primary
        : AppColors.accentFor(context);

    return Positioned(
      left: screenSize.width * cfg[0],
      bottom: screenSize.height * cfg[1],
      child: IgnorePointer(
        child: Icon(
              index.isEven ? Icons.star_rounded : Icons.auto_awesome_rounded,
              size: cfg[2],
              color: color,
            )
            .animate(delay: Duration(milliseconds: cfg[3].toInt()))
            .scale(
              begin: const Offset(0.1, 0.1),
              end: const Offset(1, 1),
              duration: 350.ms,
              curve: Curves.elasticOut,
            )
            .then()
            .moveY(
              begin: 0,
              end: -60,
              duration: 750.ms,
              curve: Curves.easeOut,
            )
            .fadeOut(duration: 600.ms),
      ),
    );
  }
}

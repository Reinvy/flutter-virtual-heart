// Fitur Chat (FR-05..FR-10) — layar utama chat.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/empty_state.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/message.dart';
import '../../models/mood_state.dart';
import '../../models/persona_config.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';
import '../persona/avatar_catalog.dart';
import '../persona/persona_controller.dart';
import '../persona/persona_profile_sheet.dart';
import '../settings/settings_controller.dart';
import 'chat_controller.dart';
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

  int _speakingMessageId = -1;
  bool _isListening = false;
  StreamSubscription<String>? _sttSubscription;
  bool _sparkleShown = false;
  bool _showSparkle = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _sttSubscription?.cancel();
    _ttsService.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final persona = ref.watch(personaProvider);
    final chatState = ref.watch(chatProvider);
    final currentMood = ref.watch(moodProvider).current;

    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.streamingBuffer != next.streamingBuffer) {
        _scrollToBottom();
      }

      if (!next.isTyping && prev?.isTyping == true && next.messages.isNotEmpty) {
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
          if (settings.ttsEnabled && settings.ttsAutoPlay) {
            _speakMessage(last, persona);
          }
        }
      }
    });

    return Scaffold(
      appBar: _buildAppBar(strings, persona, currentMood),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildMessageList(strings, chatState.messages, chatState.isTyping,
                    chatState.streamingBuffer, persona),
              ),
              InputBar(
                enabled: !chatState.isTyping,
                isListening: _isListening,
                onMicTap: _handleMicTap,
                onSend: (text) {
                  HapticFeedback.lightImpact();
                  ref.read(chatProvider.notifier).sendMessage(text);
                },
              ),
            ],
          ),
          if (_showSparkle) const IgnorePointer(child: SizedBox.expand(child: _SparkleOverlay())),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AppStrings strings,
    PersonaConfig? persona,
    MoodType currentMood,
  ) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => showPersonaProfileSheet(context, persona),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceXs),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              personaAvatar(name: persona?.name, avatarId: persona?.avatarId, size: 36),
              Positioned(
                right: -2,
                bottom: -2,
                child: Text(_moodEmoji(currentMood), style: const TextStyle(fontSize: 12, height: 1))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.85, end: 1.05, duration: 1400.ms, curve: Curves.easeInOut),
              ),
            ],
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () => showPersonaProfileSheet(context, persona),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              persona?.name ?? strings.appName,
              style: AppTextStyles.personaName(color: textColor),
            ),
            const MoodIndicator(),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.bookmark_outline_rounded, color: textColor.withAlpha(153)),
          tooltip: 'Memory',
          onPressed: () => context.push(AppRoutes.memory),
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: textColor.withAlpha(153)),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }

  static String _moodEmoji(MoodType mood) => switch (mood) {
    MoodType.happy => '😊',
    MoodType.longing => '🥺',
    MoodType.playful => '😄',
    MoodType.sad => '😔',
    MoodType.excited => '🤩',
  };

  Future<void> _speakMessage(Message message, PersonaConfig? persona) async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.ttsEnabled) return;

    if (_speakingMessageId == message.id) {
      await _ttsService.stop();
      if (mounted) setState(() => _speakingMessageId = -1);
      return;
    }

    setState(() => _speakingMessageId = message.id);
    await _ttsService.speak(
      message.content,
      gender: persona?.gender ?? PersonaGender.girlfriend,
      onDone: () {
        if (mounted) setState(() => _speakingMessageId = -1);
      },
    );
  }

  Future<void> _handleMicTap() async {
    final strings = ref.read(appStringsProvider);
    if (_isListening) {
      await _sttService.stopListening();
      await _sttSubscription?.cancel();
      _sttSubscription = null;
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final ok = await _sttService.initialize();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.chatSttUnavailable),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    HapticFeedback.lightImpact();

    String lastTranscript = '';
    final stream = _sttService.startListening();

    _sttSubscription = stream.listen(
      (transcript) => lastTranscript = transcript,
      onDone: () {
        if (mounted) setState(() => _isListening = false);
        if (lastTranscript.trim().isNotEmpty) {
          HapticFeedback.lightImpact();
          ref.read(chatProvider.notifier).sendMessage(lastTranscript.trim());
        }
        _sttSubscription = null;
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
        _sttSubscription = null;
      },
      cancelOnError: true,
    );
  }

  Widget _buildMessageList(
    AppStrings strings,
    List<Message> messages,
    bool isTyping,
    String streamingBuffer,
    PersonaConfig? persona,
  ) {
    final itemCount = messages.length + (isTyping ? 1 : 0);

    if (itemCount == 0) {
      return _EmptyChat(strings: strings, personaName: persona?.name, persona: persona);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXs),
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
          return const TypingIndicator();
        }

        return ChatBubble(
          key: ValueKey(messages[i].id),
          message: messages[i],
          persona: persona,
          onSpeak: messages[i].role == MessageRole.assistant
              ? () => _speakMessage(messages[i], persona)
              : null,
          isSpeaking: _speakingMessageId == messages[i].id,
        );
      },
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
    return Column(
      children: [
        const Spacer(flex: 3),
        Expanded(
          flex: 5,
          child: EmptyState(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.accent,
            title: fillPlaceholders(strings.chatEmptyGreeting, {'name': personaName ?? 'Sweetheart'}),
            body: strings.chatEmptyBody,
            action: personaAvatar(
              name: personaName,
              avatarId: persona?.avatarId,
              size: 72,
            ),
          ),
        ),
        const Spacer(flex: 4),
      ],
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
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        for (int i = 0; i < _configs.length; i++) _SparkleParticle(index: i, screenSize: size),
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
    final motionOk = !MediaQuery.disableAnimationsOf(context);
    final color = index % 3 == 0
        ? AppColors.gold
        : index % 3 == 1
        ? AppColors.primary
        : AppColors.accent;

    return Positioned(
      left: screenSize.width * cfg[0],
      bottom: screenSize.height * cfg[1],
      child: Semantics(
        label: null,
        child: Icon(
              index.isEven ? Icons.star_rounded : Icons.auto_awesome_rounded,
              size: cfg[2],
              color: color,
            )
            .animate(
              delay: motionOk ? Duration(milliseconds: cfg[3].toInt()) : Duration.zero,
            )
            .scale(
              begin: const Offset(0.1, 0.1),
              end: const Offset(1, 1),
              duration: 350.ms,
              curve: Curves.elasticOut,
            )
            .then()
            .moveY(begin: 0, end: -60, duration: 750.ms, curve: Curves.easeOut)
            .fadeOut(duration: 600.ms),
      ),
    );
  }
}

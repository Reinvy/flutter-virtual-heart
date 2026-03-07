import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/message.dart';
import '../../data/models/mood_state.dart';
import '../../data/models/persona_config.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/objectbox_provider.dart';
import '../../providers/router_provider.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';
import 'chat_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/input_bar.dart';
import 'widgets/mood_indicator.dart';
import 'widgets/persona_profile_sheet.dart';
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

  /// ID of the [Message] currently being spoken (-1 = none).
  int _speakingMessageId = -1;

  /// Whether the mic is actively listening.
  bool _isListening = false;

  StreamSubscription<String>? _sttSubscription;

  /// Whether the sparkle effect has already fired this session.
  bool _sparkleShown = false;

  /// Whether to currently display the sparkle overlay.
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
    final db = ref.read(objectBoxServiceProvider);
    final personas = db.personaBox.getAll();
    final persona = personas.isNotEmpty ? personas.first : null;

    final chatState = ref.watch(chatProvider);
    final currentMood = ref.watch(moodProvider).current;

    // Scroll down whenever a new message arrives or streaming updates.
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.streamingBuffer != next.streamingBuffer) {
        _scrollToBottom();
      }

      // Auto-play TTS when AI finishes responding.
      if (!next.isTyping && prev?.isTyping == true && next.messages.isNotEmpty) {
        final last = next.messages.last;
        if (last.role == MessageRole.assistant) {
          // Sparkle overlay on the first AI response of the session.
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
      appBar: _buildAppBar(context, persona, currentMood),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildMessageList(
                  chatState.messages,
                  chatState.isTyping,
                  chatState.streamingBuffer,
                  persona,
                ),
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
    BuildContext context,
    PersonaConfig? persona,
    MoodType currentMood,
  ) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => showPersonaProfileSheet(context, persona),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: _AppBarAvatar(persona: persona, moodType: currentMood),
        ),
      ),
      title: GestureDetector(
        onTap: () => showPersonaProfileSheet(context, persona),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              persona?.name ?? 'VirtualHeart',
              style: AppTextStyles.personaName(color: Theme.of(context).colorScheme.onSurface),
            ),
            const MoodIndicator(),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
          ),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }

  // ── TTS ───────────────────────────────────────────────────────────────────

  Future<void> _speakMessage(Message message, PersonaConfig? persona) async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.ttsEnabled) return;

    // Tap again to stop the currently playing message.
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

  // ── STT ───────────────────────────────────────────────────────────────────

  Future<void> _handleMicTap() async {
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
          const SnackBar(
            content: Text('Speech recognition tidak tersedia di perangkat ini'),
            duration: Duration(seconds: 2),
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
    List<Message> messages,
    bool isTyping,
    String streamingBuffer,
    PersonaConfig? persona,
  ) {
    final itemCount = messages.length + (isTyping ? 1 : 0);

    if (itemCount == 0) {
      return _EmptyChat(personaName: persona?.name);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      itemCount: itemCount,
      itemBuilder: (ctx, i) {
        // Last slot when typing: streaming bubble or three-dot indicator.
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

// ── AppBar avatar ─────────────────────────────────────────────────────────────

class _AppBarAvatar extends StatelessWidget {
  const _AppBarAvatar({this.persona, this.moodType});

  final PersonaConfig? persona;
  final MoodType? moodType;

  static const Map<String, Color> _colors = {
    'gf_1': Color(0xFFC2507A),
    'gf_2': Color(0xFF7B5EA7),
    'gf_3': Color(0xFFE8506A),
    'gf_4': Color(0xFFD4739A),
    'gf_5': Color(0xFF9B6EBA),
    'gf_6': Color(0xFFC47BAA),
    'bf_1': Color(0xFF5B8CCC),
    'bf_2': Color(0xFF7B5EA7),
    'bf_3': Color(0xFF3D8B6E),
    'bf_4': Color(0xFF4E7AA0),
    'bf_5': Color(0xFF6472B5),
    'bf_6': Color(0xFF5D9E8C),
  };

  static String _moodEmoji(MoodType mood) => switch (mood) {
    MoodType.happy => '😊',
    MoodType.longing => '🥺',
    MoodType.playful => '😄',
    MoodType.sad => '😔',
    MoodType.excited => '🤩',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[persona?.avatarId] ?? AppColors.primary;
    final initial = (persona?.name.isNotEmpty ?? false) ? persona!.name[0].toUpperCase() : '♥';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppTextStyles.button(color: Colors.white).copyWith(fontSize: 16),
          ),
        ),
        if (moodType != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Text(_moodEmoji(moodType!), style: const TextStyle(fontSize: 12, height: 1))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.85, end: 1.05, duration: 1400.ms, curve: Curves.easeInOut),
          ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({this.personaName});

  final String? personaName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_rounded, color: AppColors.heartRed, size: 48),
          const SizedBox(height: AppSizes.md),
          Text(
            'Halo, ${personaName ?? 'Sayang'}!',
            style: AppTextStyles.headingLarge(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Mulai percakapanmu...',
            style: AppTextStyles.bodyMedium(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Sparkle overlay ───────────────────────────────────────────────────────────

/// Full-screen sparkle / star particle overlay shown on the first AI response
/// of a session (flutter_animate, pointer-ignored).
class _SparkleOverlay extends StatelessWidget {
  const _SparkleOverlay();

  // [left_fraction, bottom_fraction, icon_size, delay_ms]
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
    final color = index % 3 == 0
        ? const Color(0xFFFFD700)
        : index % 3 == 1
        ? AppColors.primary
        : AppColors.heartRed;

    return Positioned(
      left: screenSize.width * cfg[0],
      bottom: screenSize.height * cfg[1],
      child:
          Icon(
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
              .moveY(begin: 0, end: -60, duration: 750.ms, curve: Curves.easeOut)
              .fadeOut(duration: 600.ms),
    );
  }
}

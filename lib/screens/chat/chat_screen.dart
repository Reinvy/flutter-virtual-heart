import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/message.dart';
import '../../data/models/persona_config.dart';
import '../../providers/objectbox_provider.dart';
import '../../providers/router_provider.dart';
import 'chat_provider.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
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

    // Scroll down whenever a new message arrives or streaming updates.
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.streamingBuffer != next.streamingBuffer) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, persona),
      body: Column(
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
            onSend: (text) {
              HapticFeedback.lightImpact();
              ref.read(chatProvider.notifier).sendMessage(text);
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, PersonaConfig? persona) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: _AppBarAvatar(persona: persona),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(persona?.name ?? 'VirtualHeart', style: AppTextStyles.personaName()),
          const MoodIndicator(),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
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

        return ChatBubble(key: ValueKey(messages[i].id), message: messages[i], persona: persona);
      },
    );
  }
}

// ── AppBar avatar ─────────────────────────────────────────────────────────────

class _AppBarAvatar extends StatelessWidget {
  const _AppBarAvatar({this.persona});

  final PersonaConfig? persona;

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

  @override
  Widget build(BuildContext context) {
    final color = _colors[persona?.avatarId] ?? AppColors.primary;
    final initial = (persona?.name.isNotEmpty ?? false) ? persona!.name[0].toUpperCase() : '♥';

    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: AppTextStyles.button(color: Colors.white).copyWith(fontSize: 16)),
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
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

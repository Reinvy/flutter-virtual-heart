import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/message.dart';
import '../../../data/models/persona_config.dart';

/// Renders a single chat message as a user or AI bubble.
///
/// - User: right-aligned, rose-pink → mauve gradient.
/// - AI: left-aligned, dark surface with mini persona avatar beside it.
///
/// Tap anywhere on the bubble to reveal/hide the timestamp.
/// Pass [isStreaming] = `true` while the AI response is still being generated.
class ChatBubble extends StatefulWidget {
  const ChatBubble({super.key, required this.message, this.persona, this.isStreaming = false});

  final Message message;
  final PersonaConfig? persona;
  final bool isStreaming;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTimestamp = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final maxWidth = MediaQuery.of(context).size.width * AppSizes.bubbleMaxWidthFraction;

    return GestureDetector(
          onTap: () => setState(() => _showTimestamp = !_showTimestamp),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar alongside AI bubbles
                    if (!isUser) ...[
                      _PersonaAvatar(persona: widget.persona),
                      const SizedBox(width: AppSizes.sm),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? null : AppColors.aiBubble,
                          gradient: isUser
                              ? const LinearGradient(
                                  colors: [AppColors.userBubble, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppSizes.radiusLg),
                            topRight: Radius.circular(isUser ? 4 : AppSizes.radiusLg),
                            bottomLeft: Radius.circular(isUser ? AppSizes.radiusLg : 4),
                            bottomRight: const Radius.circular(AppSizes.radiusLg),
                          ),
                        ),
                        child: _BubbleContent(
                          message: widget.message,
                          isUser: isUser,
                          isStreaming: widget.isStreaming,
                        ),
                      ),
                    ),
                  ],
                ),
                // Timestamp (hidden by default, revealed on tap)
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: _showTimestamp
                      ? Padding(
                          padding: EdgeInsets.only(
                            top: AppSizes.xs,
                            left: isUser ? 0 : AppSizes.avatarSm + AppSizes.sm + 4,
                            right: isUser ? 4 : 0,
                          ),
                          child: Text(
                            DateFormatter.formatTime(widget.message.timestamp),
                            style: AppTextStyles.timestamp(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.12, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }
}

// ── Bubble content ─────────────────────────────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message, required this.isUser, required this.isStreaming});

  final Message message;
  final bool isUser;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final text = message.content.isEmpty ? '...' : message.content;

    if (isUser) {
      return Text(text, style: AppTextStyles.bubbleText(color: AppColors.textPrimary));
    }

    // AI response rendered as Markdown.
    return GptMarkdown(text, style: AppTextStyles.bubbleText(color: AppColors.textPrimary));
  }
}

// ── Persona avatar ─────────────────────────────────────────────────────────────

/// Small circular avatar displayed beside AI chat bubbles.
class _PersonaAvatar extends StatelessWidget {
  const _PersonaAvatar({this.persona});

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
      width: AppSizes.avatarSm,
      height: AppSizes.avatarSm,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: AppTextStyles.button(color: Colors.white).copyWith(fontSize: 14)),
    );
  }
}

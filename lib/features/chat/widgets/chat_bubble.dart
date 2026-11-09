// Fitur Chat (FR-05) — bubble pesan (docs/DESIGN.md §3.3).
//
// - User: align kanan, solid primary, teks onPrimary.
// - AI: align kiri, surfaceContainerLow, teks onSurface, markdown,
//   avatar persona kecil di samping.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../core/design/components/speaker_button.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/message.dart';
import '../../../models/persona_config.dart';
import '../../persona/avatar_catalog.dart';

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.persona,
    this.isStreaming = false,
    this.onSpeak,
    this.isSpeaking = false,
    this.speakerLabel,
  });

  final Message message;
  final PersonaConfig? persona;
  final bool isStreaming;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  /// Label aksesibilitas untuk tombol speaker.
  final String? speakerLabel;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTimestamp = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final maxWidth = MediaQuery.of(context).size.width * AppSizes.bubbleMaxWidthFraction;
    final scheme = Theme.of(context).colorScheme;

    final bubble = GestureDetector(
          onTap: () => setState(() => _showTimestamp = !_showTimestamp),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceXxs),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser) ...[
                      personaAvatar(
                        name: widget.persona?.name,
                        avatarId: widget.persona?.avatarId,
                        size: AppSizes.avatarSm,
                      ),
                      const SizedBox(width: AppSizes.spaceXs),
                    ],
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.bubblePaddingH,
                            vertical: AppSizes.bubblePaddingV,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? scheme.primary
                                : scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(AppSizes.radiusMd),
                              topRight: Radius.circular(isUser ? 4 : AppSizes.radiusMd),
                              bottomLeft: Radius.circular(isUser ? AppSizes.radiusMd : 4),
                              bottomRight: const Radius.circular(AppSizes.radiusMd),
                            ),
                          ),
                          child: _BubbleContent(
                            message: widget.message,
                            isUser: isUser,
                            isStreaming: widget.isStreaming,
                          ),
                        ),
                      ),
                    ),
                    if (!isUser && widget.onSpeak != null) ...[
                      const SizedBox(width: AppSizes.spaceXxs),
                      SpeakerButton(
                        isSpeaking: widget.isSpeaking,
                        onTap: widget.onSpeak,
                        semanticLabel: widget.speakerLabel,
                      ),
                    ],
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: _showTimestamp
                      ? Padding(
                          padding: EdgeInsets.only(
                            top: AppSizes.spaceXxs,
                            left: isUser ? 0 : AppSizes.avatarSm + AppSizes.spaceXs + 4,
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
        );

    // Bubble streaming tidak dianimasikan ulang pada tiap token.
    if (widget.isStreaming) return bubble;
    return bubble
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.12, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message, required this.isUser, required this.isStreaming});

  /// `![alt](url)` — dibuang agar model tidak bisa memicu fetch gambar.
  static final RegExp _markdownImagePattern = RegExp(r'!\[[^\]]*\]\([^)]*\)');

  final Message message;
  final bool isUser;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final text = message.content.isEmpty ? '...' : message.content;
    // User: teks terang di atas primary. AI: teks utama (ikuti mode).
    final textColor = isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    if (isUser) {
      return Text(text, style: AppTextStyles.bubbleText(color: textColor));
    }
    // Privasi: markdown dari model tidak boleh memicu permintaan jaringan.
    // `![alt](url)` dibuang sebelum render, dan `imageBuilder` menutup jalur
    // gambar lain (HTML <img>, autolink gambar).
    final sanitized = _markdownImagePattern.hasMatch(text)
        ? text.replaceAll(_markdownImagePattern, '')
        : text;
    return GptMarkdown(
      sanitized,
      style: AppTextStyles.bubbleText(color: textColor),
      html: false,
      imageBuilder: (_, _, _, _) => const SizedBox.shrink(),
    );
  }
}

// Fitur Chat (FR-05) — pesan user (kapsul solid) & pesan AI (Editorial Thread).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../core/design/components/speaker_button.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_durations.dart';
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
    this.animateEntry = true,
    this.onSpeak,
    this.isSpeaking = false,
    this.speakerLabel,
  });
  final Message message;
  final PersonaConfig? persona;
  final bool isStreaming;
  final bool animateEntry;
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

    final Widget item = isUser
        ? _buildUserBubble(context)
        : _buildEditorialThread(context);

    final tapped = GestureDetector(
      onTap: () => setState(() => _showTimestamp = !_showTimestamp),
      behavior: HitTestBehavior.opaque,
      child: item,
    );

    if (widget.isStreaming || !widget.animateEntry) return tapped;
    if (MediaQuery.disableAnimationsOf(context)) return tapped;
    return tapped
        .animate()
        .slideY(
          begin: 0.05,
          end: 0,
          duration: AppDurations.durationFast,
          curve: AppDurations.curveStandard,
        );
  }

  Widget _buildUserBubble(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxWidth = math.min(
      MediaQuery.of(context).size.width * 0.78,
      AppSizes.bubbleMaxWidth,
    );
    final radius = AppSizes.radiusBubble;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pageGutter,
        vertical: AppSizes.spaceXxs + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                key: const ValueKey('chat-bubble-user'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceMd,
                  vertical: AppSizes.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.userBubbleBgFor(context),
                  border: Border.all(
                    color: AppColors.userBubbleBorderFor(context),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                    bottomRight: const Radius.circular(AppSizes.bubbleTail),
                  ),
                ),
                child: _BubbleContent(
                  message: widget.message,
                  isUser: true,
                ),
              ),
            ),
          ),
          _buildTimestamp(
            context,
            leftPadding: 0,
            rightPadding: 4,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialThread(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxWidth = math.min(
      MediaQuery.of(context).size.width - AppSizes.pageGutter * 2,
      AppSizes.bubbleMaxWidth,
    );
    final personaName = widget.persona?.name ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pageGutter,
        vertical: AppSizes.spaceXs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceSm),
                    Expanded(
                      child: Container(
                        key: const ValueKey('chat-bubble-assistant'),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                personaAvatar(
                                  context,
                                  name: widget.persona?.name,
                                  avatarId: widget.persona?.avatarId,
                                  size: 24,
                                ),
                                if (personaName.isNotEmpty) ...[
                                  const SizedBox(width: AppSizes.spaceXs),
                                  Expanded(
                                    child: Text(
                                      personaName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.titleSmall(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ] else
                                  const Spacer(),
                                if (widget.onSpeak != null)
                                  SpeakerButton(
                                    isSpeaking: widget.isSpeaking,
                                    onTap: widget.onSpeak,
                                    semanticLabel: widget.speakerLabel,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _BubbleContent(
                              message: widget.message,
                              isUser: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTimestamp(
                context,
                leftPadding: AppSizes.spaceSm + 2,
                rightPadding: 0,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimestamp(
    BuildContext context, {
    required double leftPadding,
    required double rightPadding,
    required Color color,
  }) {
    return AnimatedSize(
      duration: AppDurations.durationFast,
      curve: AppDurations.curveStandard,
      child: _showTimestamp
          ? Padding(
              padding: EdgeInsets.only(
                top: AppSizes.spaceXxs,
                left: leftPadding,
                right: rightPadding,
              ),
              child: Text(
                DateFormatter.formatTime(widget.message.timestamp),
                style: AppTextStyles.timestamp(color: color),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message, required this.isUser});

  /// `![alt](url)` — dibuang agar model tidak bisa memicu fetch gambar.
  static final RegExp _markdownImagePattern = RegExp(r'!\[[^\]]*\]\([^)]*\)');

  final Message message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final text = message.content.isEmpty ? '...' : message.content;
    final textColor = isUser
        ? AppColors.bubbleUserOnFor(context)
        : Theme.of(context).colorScheme.onSurface;

    if (isUser) {
      return Text(text, style: AppTextStyles.bubbleText(color: textColor));
    }
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

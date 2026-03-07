import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/text_styles.dart';

/// Message input bar with a text field, microphone button, and send button.
///
/// [onSend] is called with the trimmed text when the user taps send or
/// submits the field. The bar is disabled (grayed out) when [enabled] is false.
/// [isListening] shows the mic as active (primary colour) while STT is running.
/// [onMicTap] is called when the mic button is tapped — start/stop logic is
/// handled by the parent; pass `null` to show the mic as unavailable.
class InputBar extends StatefulWidget {
  const InputBar({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.isListening = false,
    this.onMicTap,
  });

  final void Function(String text) onSend;
  final bool enabled;
  final bool isListening;
  final VoidCallback? onMicTap;

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
  }

  void _handleMicTap() {
    if (widget.onMicTap != null) {
      widget.onMicTap!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition tidak tersedia di perangkat ini'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.secondary.withAlpha(51), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Microphone button (STT)
            _IconButton(
              icon: widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              iconColor: widget.isListening ? AppColors.primary : null,
              onTap: widget.enabled ? _handleMicTap : null,
            ),
            const SizedBox(width: AppSizes.sm),
            // Text field
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.inputBarHeight,
                  maxHeight: 120,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: AppTextStyles.bubbleText(),
                  decoration: InputDecoration(
                    hintText: 'Ceritakan harimu...',
                    hintStyle: AppTextStyles.inputHint(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.aiBubble,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Send button — active only when there is text
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, __) {
                final canSend = value.text.trim().isNotEmpty && widget.enabled;
                return _SendButton(onTap: canSend ? _handleSend : null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon button ────────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap, this.iconColor});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          onTap: onTap,
          child: Icon(
            icon,
            color: active
                ? (iconColor ?? AppColors.textSecondary)
                : AppColors.textSecondary.withAlpha(102),
            size: AppSizes.iconMd,
          ),
        ),
      ),
    );
  }
}

// ── Send button ────────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.primary.withAlpha(76),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// Fitur Chat (FR-06) — input bar (text + mic + send) (docs/DESIGN.md §3.2).
import 'package:flutter/material.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/extensions.dart';

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
      final strings = context.read(appStringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatSttUnavailable), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.read(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final fieldFill = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevated;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceXs),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: AppColors.secondary.withAlpha(51), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _IconButton(
              icon: widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              iconColor: widget.isListening ? AppColors.primary : null,
              onTap: widget.enabled ? _handleMicTap : null,
            ),
            const SizedBox(width: AppSizes.spaceXs),
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
                  style: AppTextStyles.bubbleText(color: textColor),
                  decoration: InputDecoration(
                    hintText: strings.chatInputHint,
                    hintStyle: AppTextStyles.inputHint(color: hintColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spaceMd,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: fieldFill,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spaceXs),
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

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap, this.iconColor});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
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
            color: active ? (iconColor ?? defaultIconColor) : defaultIconColor.withAlpha(102),
            size: AppSizes.iconMd,
          ),
        ),
      ),
    );
  }
}

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

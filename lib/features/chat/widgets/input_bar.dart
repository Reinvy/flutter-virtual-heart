// Fitur Chat (FR-06) — input bar (text + mic + send) (docs/DESIGN.md §3.2).
//
// Field pill, mic & send 48×48 (target sentuh minimum), warna via tema.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';

class InputBar extends ConsumerStatefulWidget {
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
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
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
      final strings = ref.read(appStringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatSttUnavailable), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.read(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceXs),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _IconButton(
              icon: widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              iconColor: widget.isListening ? scheme.primary : null,
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
                  maxLength: 2000, // FR-05: batas input pesan
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: AppTextStyles.bubbleText(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: strings.chatInputHint,
                    hintStyle: AppTextStyles.inputHint(color: scheme.onSurfaceVariant),
                    counterText: '', // sembunyikan counter, batas tetap aktif
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spaceMd,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHigh,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spaceXs),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, _) {
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
    final scheme = Theme.of(context).colorScheme;
    final defaultIconColor = scheme.onSurfaceVariant;
    return SizedBox(
      width: AppSizes.touchTarget,
      height: AppSizes.touchTarget,
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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: AppSizes.touchTarget,
        height: AppSizes.touchTarget,
        decoration: BoxDecoration(
          color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.send_rounded,
          color: active ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.38),
          size: 20,
        ),
      ),
    );
  }
}

// Fitur Chat (FR-06) — input bar (text + mic + send) (docs/DESIGN.md §3.2).
//
// Permukaan melayang dengan pill field; mic & send 48×48 (target sentuh
// minimum), warna dan gradien dari token tema.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_effects.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';

class InputBar extends ConsumerStatefulWidget {
  const InputBar({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.isTyping = false,
    this.isListening = false,
    this.onMicTap,
    this.onStop,
    this.controller,
  });

  final void Function(String text) onSend;
  final bool enabled;
  final bool isTyping;
  final bool isListening;
  final VoidCallback? onMicTap;

  /// Dipanggil saat tombol stop ditekan (menghentikan generasi).
  final VoidCallback? onStop;

  /// Controller eksternal opsional (mis. untuk mengisi transkrip STT).
  final TextEditingController? controller;

  @override
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    // Hanya dispose controller yang dibuat internal.
    if (widget.controller == null) _controller.dispose();
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
        SnackBar(
          content: Text(strings.chatSttUnavailable),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.read(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.spaceSm + 4,
        0,
        AppSizes.spaceSm + 4,
        AppSizes.spaceXs,
      ),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: AppShadows.floating(context),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _MicButton(
              isListening: widget.isListening,
              onTap: widget.enabled ? _handleMicTap : null,
              semanticLabel: widget.isListening
                  ? strings.chatMicStop
                  : strings.chatMicStart,
            ),
            const SizedBox(width: AppSizes.spaceXs),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.chatInputHeight - 8,
                  maxHeight: AppSizes.inputMaxHeight,
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
                    hintStyle: AppTextStyles.inputHint(
                      color: scheme.onSurfaceVariant,
                    ),
                    counterText: null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spaceMd,
                      vertical: AppSizes.spaceSm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusBubble),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusBubble),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusBubble),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                  ),
                  buildCounter:
                      (_, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => currentLength >= 1800
                      ? Text(
                          '$currentLength/2000',
                          style: AppTextStyles.timestamp(
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spaceXs),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, _) {
                final canSend = value.text.trim().isNotEmpty && widget.enabled;
                return _SendButton(
                  isStop: widget.isTyping,
                  semanticLabel: widget.isTyping
                      ? strings.chatStop
                      : strings.chatSend,
                  onTap: widget.isTyping
                      ? widget.onStop
                      : (canSend ? _handleSend : null),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.isListening,
    required this.onTap,
    required this.semanticLabel,
  });

  final bool isListening;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _motionOk = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ok = !MediaQuery.disableAnimationsOf(context);
    if (ok == _motionOk) return;
    _motionOk = ok;
    if (ok && widget.isListening) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_motionOk) return;
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.onTap != null;
    final listening = widget.isListening;
    final iconColor = listening
        ? scheme.onPrimary
        : (active
              ? scheme.onSurfaceVariant
              : scheme.onSurfaceVariant.withValues(alpha: 0.4));

    final button = SizedBox(
      width: AppSizes.touchTarget,
      height: AppSizes.touchTarget,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: AppSizes.avatarNav,
              height: AppSizes.avatarNav,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listening ? null : scheme.surfaceContainerLow,
                gradient: listening ? AppGradients.primaryAction(context) : null,
              ),
              child: Icon(
                listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );

    if (!listening || !_motionOk) {
      return Semantics(button: true, label: widget.semanticLabel, child: button);
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: AppSizes.avatarNav + 12 * t,
                height: AppSizes.avatarNav + 12 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.35 * (1 - t)),
                    width: 1.5,
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: button,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({this.onTap, this.isStop = false, this.semanticLabel});

  final VoidCallback? onTap;
  final bool isStop;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null || isStop;
    final scheme = Theme.of(context).colorScheme;
    final button = SizedBox(
      width: AppSizes.touchTarget,
      height: AppSizes.touchTarget,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: AppSizes.avatarNav,
            height: AppSizes.avatarNav,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? null : scheme.onSurface.withValues(alpha: 0.06),
              gradient: active ? AppGradients.primaryAction(context) : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              isStop ? Icons.stop_rounded : Icons.send_rounded,
              color: active
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.38),
              size: 20,
            ),
          ),
        ),
      ),
    );
    if (semanticLabel == null) return button;
    return Semantics(button: true, label: semanticLabel, child: button);
  }
}

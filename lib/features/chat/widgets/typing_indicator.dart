// Fitur Chat (FR-08) — indikator mengetik (3 titik).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design/tokens/app_effects.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../models/persona_config.dart';
import '../../persona/avatar_catalog.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, this.persona});

  final PersonaConfig? persona;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceMd,
        vertical: AppSizes.spaceXxs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          personaAvatar(
            name: persona?.name,
            avatarId: persona?.avatarId,
            size: AppSizes.avatarSm,
          ),
          const SizedBox(width: AppSizes.spaceXs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceMd,
              vertical: AppSizes.spaceSm,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusBubble),
                topRight: Radius.circular(AppSizes.radiusBubble),
                bottomLeft: Radius.circular(AppSizes.bubbleTail),
                bottomRight: Radius.circular(AppSizes.radiusBubble),
              ),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
              boxShadow: AppShadows.card(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  _Dot(
                    delay: Duration(milliseconds: i * 160),
                    color: scheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.delay, required this.color});

  final Duration delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    // Hormati pengaturan "kurangi animasi": titik tetap diam.
    if (MediaQuery.disableAnimationsOf(context)) return dot;
    return dot
        .animate(delay: delay, onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 380.ms, curve: Curves.easeInOut);
  }
}

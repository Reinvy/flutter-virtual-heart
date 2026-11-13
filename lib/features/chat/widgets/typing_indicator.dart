// Fitur Chat (FR-08) — indikator mengetik editorial thread.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
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
        horizontal: AppSizes.pageGutter,
        vertical: AppSizes.spaceXs,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    personaAvatar(
                      context,
                      name: persona?.name,
                      avatarId: persona?.avatarId,
                      size: 24,
                    ),
                    if (persona?.name.isNotEmpty ?? false) ...[
                      const SizedBox(width: AppSizes.spaceXs),
                      Text(
                        persona!.name,
                        style: AppTextStyles.titleSmall(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.spaceXs),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _PulseSquare(
                          delay: Duration(milliseconds: i * 160),
                          color: scheme.secondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseSquare extends StatelessWidget {
  const _PulseSquare({required this.delay, required this.color});

  final Duration delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return mark;
    return mark
        .animate(delay: delay, onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.35, end: 1.0, duration: 420.ms, curve: Curves.easeInOut);
  }
}

// Fitur Chat (FR-08) — indikator mengetik (3 titik).
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_sizes.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dotColor = AppColors.primaryDeep;
    final bubbleBg = scheme.surfaceContainerLow;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceXxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.55),
                  scheme.primaryContainer,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.spaceXs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceSm),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(AppSizes.radiusMd),
                bottomLeft: Radius.circular(AppSizes.radiusMd),
                bottomRight: Radius.circular(AppSizes.radiusMd),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  _Dot(delay: Duration(milliseconds: i * 160), color: dotColor),
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
    return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(delay: delay, onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 380.ms, curve: Curves.easeInOut);
  }
}

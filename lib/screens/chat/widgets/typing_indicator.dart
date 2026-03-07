import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Three bouncing dots that indicate the AI is generating a response.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Placeholder matching the ChatBubble avatar size
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(76),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.aiBubble,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(AppSizes.radiusLg),
                bottomLeft: Radius.circular(AppSizes.radiusLg),
                bottomRight: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  _Dot(delay: Duration(milliseconds: i * 160)),
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
  const _Dot({required this.delay});

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
        )
        .animate(delay: delay, onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 380.ms, curve: Curves.easeInOut);
  }
}

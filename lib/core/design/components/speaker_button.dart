// Komponen shared — SpeakerButton (docs/DESIGN.md §3.3)
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Tombol play/stop TTS kecil di samping bubble AI.
class SpeakerButton extends StatelessWidget {
  const SpeakerButton({super.key, required this.isSpeaking, this.onTap});

  final bool isSpeaking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          size: 20,
          color: isSpeaking ? AppColors.primary : subtleColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

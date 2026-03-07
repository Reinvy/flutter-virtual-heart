import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_settings.dart';
import '../../../providers/app_settings_provider.dart';
import 'section_widgets.dart';

class VoiceSection extends ConsumerWidget {
  final AppSettings settings;
  const VoiceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, 'Suara', Icons.record_voice_over_rounded),
        sectionCard(
          context: context,
          children: [
            SwitchListTile(
              dense: true,
              secondary: const Icon(Icons.volume_up_rounded),
              title: const Text('Aktifkan Text-to-Speech'),
              subtitle: const Text('AI akan membacakan pesannya'),
              value: settings.ttsEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(appSettingsProvider.notifier).save(settings.copyWith(ttsEnabled: v));
              },
            ),
            if (settings.ttsEnabled)
              SwitchListTile(
                dense: true,
                secondary: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Auto-play'),
                subtitle: const Text('Langsung bacakan setiap balasan AI'),
                value: settings.ttsAutoPlay,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref.read(appSettingsProvider.notifier).save(settings.copyWith(ttsAutoPlay: v));
                },
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 180.ms).slideY(begin: 0.04, end: 0);
  }
}

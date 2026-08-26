// Settings — Voice (TTS, FR-07).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/section_card.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../settings_controller.dart';

class VoiceSection extends ConsumerWidget {
  final AppSettings settings;
  const VoiceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, strings.settingsVoice, Icons.record_voice_over_rounded),
        sectionCard(
          context: context,
          children: [
            SwitchListTile(
              dense: true,
              secondary: const Icon(Icons.volume_up_rounded),
              title: Text(strings.settingsTtsEnable),
              subtitle: Text(strings.settingsTtsEnableDesc),
              value: settings.ttsEnabled,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(appSettingsProvider.notifier).save(settings.copyWith(ttsEnabled: v));
              },
            ),
            if (settings.ttsEnabled)
              SwitchListTile(
                dense: true,
                secondary: const Icon(Icons.play_circle_outline_rounded),
                title: Text(strings.settingsTtsAutoPlay),
                subtitle: Text(strings.settingsTtsAutoPlayDesc),
                value: settings.ttsAutoPlay,
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

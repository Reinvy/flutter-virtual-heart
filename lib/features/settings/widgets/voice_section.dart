// Settings — Voice (TTS, FR-07 + status izin mikrofon FR-18).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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
            _MicPermissionTile(strings: strings),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 180.ms).slideY(begin: 0.04, end: 0);
  }
}

/// Menampilkan status izin mikrofon (FR-18) secara jujur.
class _MicPermissionTile extends ConsumerStatefulWidget {
  const _MicPermissionTile({required this.strings});

  final AppStrings strings;

  @override
  ConsumerState<_MicPermissionTile> createState() => _MicPermissionTileState();
}

class _MicPermissionTileState extends ConsumerState<_MicPermissionTile> {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await Permission.microphone.status;
    if (mounted) setState(() => _status = status);
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _status;
    final granted = status == PermissionStatus.granted || status == PermissionStatus.limited;
    final denied = status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied;

    if (status == null || !denied) {
      return ListTile(
        dense: true,
        leading: Icon(Icons.mic_none_rounded, color: scheme.onSurfaceVariant),
        title: Text(widget.strings.settingsMicPermissionDenied),
        subtitle: Text(widget.strings.settingsMicPermissionOpenSettings),
        trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        onTap: granted ? null : _openSettings,
      );
    }

    return ListTile(
      dense: true,
      leading: Icon(Icons.mic_none_rounded, color: scheme.primary),
      title: Text(widget.strings.settingsMicPermissionGranted),
      trailing: Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
    );
  }
}

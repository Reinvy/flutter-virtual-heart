// Settings — Voice (FR-07): backend (gemma/system), pilihan model speech,
// status izin mikrofon (FR-18).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../services/ai/speech_model_catalog.dart';
import '../../../services/stt_service.dart';
import '../../../services/tts_service.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'settings_permission_row.dart';
import 'settings_row.dart';
import 'settings_section.dart';

class VoiceSection extends ConsumerWidget {
  final AppSettings settings;
  const VoiceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final gemma = settings.ttsBackend == 'gemma' || settings.sttBackend == 'gemma';
    return SettingsSection(
      title: strings.settingsVoice,
      icon: Icons.record_voice_over_rounded,
      children: [
        SettingsRow(
          icon: Icons.volume_up_rounded,
          title: strings.settingsTtsEnable,
          subtitle: strings.settingsTtsEnableDesc,
          trailing: Switch.adaptive(
            value: settings.ttsEnabled,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              ref
                  .read(appSettingsProvider.notifier)
                  .save(settings.copyWith(ttsEnabled: v));
            },
          ),
        ),
        if (settings.ttsEnabled)
          SettingsRow(
            icon: Icons.play_circle_outline_rounded,
            title: strings.settingsTtsAutoPlay,
            subtitle: strings.settingsTtsAutoPlayDesc,
            trailing: Switch.adaptive(
              value: settings.ttsAutoPlay,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref
                    .read(appSettingsProvider.notifier)
                    .save(settings.copyWith(ttsAutoPlay: v));
              },
            ),
          ),
        _BackendSelector(settings: settings),
        if (gemma) ..._speechModelChildren(context, ref, settings, strings),
        _MicPermissionTile(strings: strings),
      ],
    );
  }
}

/// Pilihan backend TTS & STT: Gemma (on-device) / System (flutter_tts).
class _BackendSelector extends ConsumerWidget {
  const _BackendSelector({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.settingsVoiceBackend,
            style: AppTextStyles.settingsLabel(),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'gemma',
                  label: Text(strings.settingsVoiceBackendOnDevice),
                  icon: const Icon(Icons.memory_rounded),
                ),
                ButtonSegment(
                  value: 'system',
                  label: Text(strings.settingsVoiceBackendSystem),
                  icon: const Icon(Icons.speaker_rounded),
                ),
              ],
              selected: {settings.ttsBackend},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                HapticFeedback.selectionClick();
                final backend = s.first;
                ref.read(appSettingsProvider.notifier).save(
                  settings.copyWith(ttsBackend: backend, sttBackend: backend),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.spaceXs),
          Text(
            settings.ttsBackend == 'system'
                ? strings.speechSystemNote
                : strings.speechGemmaNote,
            style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Baris header grup model speech di dalam kartu section.
Widget _speechGroupHeader(BuildContext context, String label) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSizes.spaceMd,
      AppSizes.spaceSm,
      AppSizes.spaceMd,
      AppSizes.spaceXxs,
    ),
    child: Text(
      label.toUpperCase(),
      style: AppTextStyles.sectionLabel(color: scheme.onSurfaceVariant),
    ),
  );
}

/// Daftar baris model speech (TTS & STT) — diratakan agar divider kartu
/// mengatur pemisahan antar baris.
List<Widget> _speechModelChildren(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  AppStrings strings,
) {
  return [
    _speechGroupHeader(context, strings.settingsVoiceTtsModel),
    ...kTtsModelOptions.map(
      (opt) => _SpeechModelTile(
        icon: Icons.record_voice_over_rounded,
        option: opt,
        selected: settings.ttsModel == opt.id,
        isActive:
            settings.ttsModel == opt.id && TtsService().isModelActive(opt.id),
        onSelect: () {
          HapticFeedback.selectionClick();
          ref
              .read(appSettingsProvider.notifier)
              .save(settings.copyWith(ttsModel: opt.id));
        },
        onDownload: (onProgress) => TtsService().ensureReady(
          backend: 'gemma',
          model: opt.id,
          onProgress: onProgress,
        ),
      ),
    ),
    _speechGroupHeader(context, strings.settingsVoiceSttModel),
    ...kSttModelOptions.map(
      (opt) => _SpeechModelTile(
        icon: Icons.mic_none_rounded,
        option: opt,
        selected: settings.sttModel == opt.id,
        isActive:
            settings.sttModel == opt.id && SttService().isModelActive(opt.id),
        onSelect: () {
          HapticFeedback.selectionClick();
          ref
              .read(appSettingsProvider.notifier)
              .save(settings.copyWith(sttModel: opt.id));
        },
        onDownload: (onProgress) => SttService().prepareModel(
          backend: 'gemma',
          model: opt.id,
          onProgress: onProgress,
        ),
      ),
    ),
  ];
}

/// Baris satu opsi model speech: nama, ukuran, status, tombol unduh.
class _SpeechModelTile extends ConsumerStatefulWidget {
  const _SpeechModelTile({
    required this.icon,
    required this.option,
    required this.selected,
    required this.isActive,
    required this.onSelect,
    required this.onDownload,
  });

  final IconData icon;
  final SpeechModelOption option;
  final bool selected;

  /// Model sudah terpasang **dan** aktif di engine.
  final bool isActive;
  final VoidCallback onSelect;
  final Future<bool> Function(void Function(int percent) onProgress) onDownload;

  @override
  ConsumerState<_SpeechModelTile> createState() => _SpeechModelTileState();
}

class _SpeechModelTileState extends ConsumerState<_SpeechModelTile> {
  bool _downloading = false;
  int _progress = 0;
  bool _installedThisSession = false;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    final ok = await widget.onDownload((p) {
      if (mounted) setState(() => _progress = p);
    });
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _installedThisSession = ok;
    });
    if (!ok) {
      final strings = ref.read(appStringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.option.isTts
                ? strings.chatTtsUnavailable
                : strings.chatSttUnavailable,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final installed = widget.isActive || _installedThisSession;
    return SettingsRow(
      icon: widget.icon,
      title: widget.option.name,
      subtitle: '${widget.option.description} • ${widget.option.sizeLabel}',
      selected: widget.selected,
      onTap: widget.onSelect,
      trailing: _downloading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: _progress / 100,
                strokeWidth: 2,
              ),
            )
          : TextButton(
              onPressed: installed ? null : _download,
              child: Text(
                installed
                    ? strings.speechModelInstalled
                    : strings.speechModelDownload,
              ),
            ),
    );
  }
}

/// Menampilkan status izin mikrofon (FR-18) secara jujur.
class _MicPermissionTile extends ConsumerStatefulWidget {
  const _MicPermissionTile({required this.strings});

  final AppStrings strings;

  @override
  ConsumerState<_MicPermissionTile> createState() => _MicPermissionTileState();
}

class _MicPermissionTileState extends ConsumerState<_MicPermissionTile>
    with WidgetsBindingObserver {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final status = await Permission.microphone.status;
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) setState(() => _status = null);
    }
  }

  Future<void> _request() async {
    try {
      await Permission.microphone.request();
    } catch (_) {
      // Izin tidak tersedia di platform ini; biarkan status apa adanya.
    }
    await _load();
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    if (status == PermissionStatus.granted ||
        status == PermissionStatus.limited) {
      return SettingsPermissionRow(
        icon: Icons.mic_rounded,
        title: widget.strings.settingsMicPermissionGranted,
        subtitle: '',
        state: SettingsPermissionState.granted,
      );
    }

    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      return SettingsPermissionRow(
        icon: Icons.mic_off_rounded,
        title: widget.strings.settingsMicPermissionDenied,
        subtitle: widget.strings.settingsMicPermissionOpenSettings,
        state: SettingsPermissionState.denied,
        actionLabel: widget.strings.settingsMicPermissionOpenSettings,
        onAction: _openSettings,
      );
    }

    return SettingsPermissionRow(
      icon: Icons.mic_none_rounded,
      title: widget.strings.settingsMicPermissionNotRequested,
      subtitle: '',
      state: SettingsPermissionState.notRequested,
      actionLabel: widget.strings.settingsMicPermissionRequest,
      onAction: _request,
    );
  }
}

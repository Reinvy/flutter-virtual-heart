// Settings — Voice (FR-07): backend (gemma/system), pilihan model speech,
// status izin mikrofon (FR-18).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/design/components/section_card.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../services/ai/speech_model_catalog.dart';
import '../../../services/stt_service.dart';
import '../../../services/tts_service.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

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
            _BackendSelector(settings: settings),
            if (settings.ttsBackend == 'gemma' || settings.sttBackend == 'gemma')
              _SpeechModelList(settings: settings),
            _MicPermissionTile(strings: strings),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 180.ms).slideY(begin: 0.04, end: 0);
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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spaceMd,
        AppSizes.spaceXs,
        AppSizes.spaceMd,
        AppSizes.spaceXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.settingsVoiceBackend, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSizes.spaceXs),
          SegmentedButton<String>(
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
          const SizedBox(height: AppSizes.spaceXs),
          Text(
            settings.ttsBackend == 'system'
                ? strings.speechSystemNote
                : strings.speechGemmaNote,
            style: AppTextStyles.moodIndicator(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Daftar model speech (TTS & STT) + tombol unduh.
class _SpeechModelList extends ConsumerWidget {
  const _SpeechModelList({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spaceMd,
            AppSizes.spaceSm,
            AppSizes.spaceMd,
            AppSizes.spaceXxs,
          ),
          child: Text(
            strings.settingsVoiceTtsModel,
            style: AppTextStyles.settingsLabel(color: scheme.primary),
          ),
        ),
        ...kTtsModelOptions.map(
          (opt) => _SpeechModelTile(
            option: opt,
            selected: settings.ttsModel == opt.id,
            isActive: settings.ttsModel == opt.id && TtsService().isModelActive(opt.id),
            onSelect: () {
              HapticFeedback.selectionClick();
              ref.read(appSettingsProvider.notifier).save(
                settings.copyWith(ttsModel: opt.id),
              );
            },
            onDownload: (onProgress) => TtsService().ensureReady(
              backend: 'gemma',
              model: opt.id,
              onProgress: onProgress,
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spaceMd,
            AppSizes.spaceSm,
            AppSizes.spaceMd,
            AppSizes.spaceXxs,
          ),
          child: Text(
            strings.settingsVoiceSttModel,
            style: AppTextStyles.settingsLabel(color: scheme.primary),
          ),
        ),
        ...kSttModelOptions.map(
          (opt) => _SpeechModelTile(
            option: opt,
            selected: settings.sttModel == opt.id,
            isActive: settings.sttModel == opt.id && SttService().isModelActive(opt.id),
            onSelect: () {
              HapticFeedback.selectionClick();
              ref.read(appSettingsProvider.notifier).save(
                settings.copyWith(sttModel: opt.id),
              );
            },
            onDownload: (onProgress) => SttService().initialize(
              backend: 'gemma',
              onProgress: onProgress,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tile satu opsi model speech: nama, ukuran, status, tombol unduh.
class _SpeechModelTile extends ConsumerStatefulWidget {
  const _SpeechModelTile({
    required this.option,
    required this.selected,
    required this.isActive,
    required this.onSelect,
    required this.onDownload,
  });

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
            widget.option.isTts ? strings.chatTtsUnavailable : strings.chatSttUnavailable,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.watch(appStringsProvider);
    final installed = widget.isActive || _installedThisSession;
    return ListTile(
      dense: true,
      leading: Icon(
        widget.option.isTts ? Icons.record_voice_over_rounded : Icons.mic_none_rounded,
        color: widget.selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(widget.option.name),
      subtitle: Text('${widget.option.description} • ${widget.option.sizeLabel}'),
      trailing: _downloading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(value: _progress / 100, strokeWidth: 2),
            )
          : TextButton(
              onPressed: installed ? null : _download,
              child: Text(
                installed ? strings.speechModelInstalled : strings.speechModelDownload,
              ),
            ),
      onTap: widget.onSelect,
      selected: widget.selected,
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
    final scheme = Theme.of(context).colorScheme;
    final status = _status;

    if (status == PermissionStatus.granted || status == PermissionStatus.limited) {
      return ListTile(
        dense: true,
        leading: Icon(Icons.mic_rounded, color: scheme.primary),
        title: Text(widget.strings.settingsMicPermissionGranted),
        trailing: Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
      );
    }

    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      return ListTile(
        dense: true,
        leading: Icon(Icons.mic_off_rounded, color: scheme.error),
        title: Text(widget.strings.settingsMicPermissionDenied),
        subtitle: Text(widget.strings.settingsMicPermissionOpenSettings),
        trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        onTap: _openSettings,
      );
    }

    return ListTile(
      dense: true,
      leading: Icon(Icons.mic_none_rounded, color: scheme.onSurfaceVariant),
      title: Text(widget.strings.settingsMicPermissionNotRequested),
      trailing: TextButton(
        onPressed: _request,
        child: Text(widget.strings.settingsMicPermissionRequest),
      ),
      onTap: _request,
    );
  }
}

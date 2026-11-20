// Settings — Voice (FR-06/FR-07): backend TTS & STT independen (system / gemma /
// elevenlabs / openai / google), model speech lokal, konfigurasi cloud, & izin mikrofon.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../services/ai/ai_provider_controller.dart';
import '../../../services/ai/speech_model_catalog.dart';
import '../../../services/stt_service.dart';
import '../../../services/tts_service.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'cloud_speech_sheet.dart';
import 'settings_permission_row.dart';
import 'settings_row.dart';
import 'settings_section.dart';

class VoiceSection extends ConsumerWidget {
  final AppSettings settings;
  const VoiceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final showLocalTts = settings.ttsBackend == 'gemma';
    final showLocalStt = settings.sttBackend == 'gemma';
    final cloudProviders = <String>{
      if (TtsService.isCloudBackend(settings.ttsBackend)) settings.ttsBackend,
      if (SttService.isCloudBackend(settings.sttBackend)) settings.sttBackend,
    };

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
              if (!v) unawaited(TtsService().stop());
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
        _BackendChipPicker(
          label: strings.settingsTtsBackendLabel,
          selected: settings.ttsBackend,
          note: _backendNote(settings.ttsBackend, strings),
          onSelect: (backend) {
            HapticFeedback.selectionClick();
            unawaited(TtsService().stop());
            ref
                .read(appSettingsProvider.notifier)
                .save(settings.copyWith(ttsBackend: backend));
          },
        ),
        _BackendChipPicker(
          label: strings.settingsSttBackendLabel,
          selected: settings.sttBackend,
          note: _backendNote(settings.sttBackend, strings),
          onSelect: (backend) {
            HapticFeedback.selectionClick();
            unawaited(SttService().cancel());
            ref
                .read(appSettingsProvider.notifier)
                .save(settings.copyWith(sttBackend: backend));
          },
        ),
        for (final provider in cloudProviders)
          _CloudSpeechConfigRow(provider: provider),
        if (showLocalTts) ..._localTtsChildren(context, ref, settings, strings),
        if (showLocalStt) ..._localSttChildren(context, ref, settings, strings),
        _MicPermissionTile(strings: strings),
      ],
    );
  }

  static String _backendNote(String backend, AppStrings strings) {
    if (backend == 'system') return strings.speechSystemNote;
    if (backend == 'gemma') return strings.speechGemmaNote;
    return strings.speechCloudNote;
  }
}

/// Pemilih backend suara berbasis `Wrap` + `ChoiceChip` (bebas overflow di 320 dp).
class _BackendChipPicker extends ConsumerWidget {
  const _BackendChipPicker({
    required this.label,
    required this.selected,
    required this.note,
    required this.onSelect,
  });

  final String label;
  final String selected;
  final String note;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final options = <(String, String)>[
      ('system', strings.settingsVoiceBackendSystem),
      ('gemma', strings.settingsVoiceBackendOnDevice),
      ('elevenlabs', strings.speechBackendElevenLabs),
      ('openai', strings.speechBackendOpenAi),
      ('google', strings.speechBackendGoogle),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.settingsLabel()),
          const SizedBox(height: 10),
          Wrap(
            spacing: AppSizes.spaceXs,
            runSpacing: AppSizes.spaceXs,
            children: [
              for (final (value, title) in options)
                ChoiceChip(
                  label: Text(title),
                  selected: selected == value,
                  onSelected: (isSelected) {
                    if (isSelected && selected != value) onSelect(value);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceXs),
          Text(
            note,
            style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CloudSpeechConfigRow extends ConsumerWidget {
  const _CloudSpeechConfigRow({required this.provider});

  final String provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final cfg = ref.watch(cloudSpeechConfigProvider);
    final (title, subtitle) = switch (provider) {
      'elevenlabs' => (
        '${strings.speechBackendElevenLabs} · ${strings.speechCloudConfigTitle}',
        '${cfg.elevenLabsVoiceName} · ${cfg.elevenLabsTtsModel} / ${cfg.elevenLabsSttModel}',
      ),
      'openai' => (
        '${strings.speechBackendOpenAi} · ${strings.speechCloudConfigTitle}',
        '${cfg.openaiTtsVoice} (${cfg.openaiTtsModel}) / ${cfg.openaiSttModel}',
      ),
      _ => (
        '${strings.speechBackendGoogle} · ${strings.speechCloudConfigTitle}',
        '${cfg.googleTtsVoiceName} · ${cfg.googleTtsModel}',
      ),
    };

    return SettingsRow(
      icon: Icons.tune_rounded,
      title: title,
      subtitle: subtitle,
      showChevron: true,
      onTap: () => showCloudSpeechConfigSheet(context, provider: provider),
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

List<Widget> _localTtsChildren(
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
          unawaited(TtsService().stop());
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
  ];
}

List<Widget> _localSttChildren(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  AppStrings strings,
) {
  return [
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
          unawaited(SttService().cancel());
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
    } catch (_) {}
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

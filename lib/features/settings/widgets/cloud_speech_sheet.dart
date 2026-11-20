// Bottom sheet konfigurasi Cloud TTS & Cloud STT (ElevenLabs / OpenAI-compatible / Google Gemini).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/components/app_sheet.dart';
import '../../../core/design/components/primary_button.dart';
import '../../../core/design/components/secondary_button.dart';
import '../../../core/design/components/sheet_header.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_effects.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../models/cloud_speech_config.dart';
import '../../../services/ai/ai_provider_controller.dart';
import '../../../services/ai/cloud_provider_catalog.dart';
import '../../../services/ai/genkit/elevenlabs_plugin.dart';
import '../../../services/ai/genkit/genkit_cloud_client.dart';
import '../../../services/ai/genkit/provider_config_builder.dart';
import '../../../services/ai/secret_store.dart';
import '../../../services/settings/settings_service.dart';
import '../../../services/tts_service.dart';

/// Membuka bottom sheet pengaturan Cloud Speech untuk [provider]
/// (`'elevenlabs'`, `'openai'`, atau `'google'`).
Future<void> showCloudSpeechConfigSheet(
  BuildContext context, {
  required String provider,
}) {
  return showAppSheet<void>(
    context,
    child: CloudSpeechConfigSheet(provider: provider),
  );
}

class CloudSpeechConfigSheet extends ConsumerStatefulWidget {
  const CloudSpeechConfigSheet({super.key, required this.provider});

  /// `'elevenlabs'` | `'openai'` | `'google'`
  final String provider;

  @override
  ConsumerState<CloudSpeechConfigSheet> createState() =>
      _CloudSpeechConfigSheetState();
}

class _CloudSpeechConfigSheetState
    extends ConsumerState<CloudSpeechConfigSheet> {
  late final TextEditingController _primaryKeyCtrl;
  late final TextEditingController _secondaryKeyCtrl; // OpenAI STT key terpisah
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _secondaryBaseUrlCtrl; // OpenAI STT baseUrl
  late final TextEditingController _ttsModelCtrl;
  late final TextEditingController _sttModelCtrl;
  late final TextEditingController _voiceCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _sttPromptCtrl;

  late double _elStability;
  late double _elSimilarity;
  late double _elStyle;
  late double _elSpeed;
  late bool _elSpeakerBoost;
  late String _elFormat;
  late bool _elSttTagEvents;
  late bool _elSttDiarize;
  late String _elVoiceName;

  late bool _reuseTtsKey;
  late bool _reuseSttKey;
  late double _openAiTtsSpeed;
  late String _openAiTtsFormat;
  late double _openAiSttTemp;

  late bool _googleReuseKey;
  late int _timeoutSeconds;

  bool _obscurePrimary = true;
  bool _obscureSecondary = true;
  bool _hasPrimaryKey = false;
  bool _hasSecondaryKey = false;
  bool _loadingVoices = false;
  bool _testingVoice = false;
  bool _saving = false;
  List<ElevenLabsVoice> _accountVoices = const [];
  String? _statusMsg;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(cloudSpeechConfigProvider);
    _primaryKeyCtrl = TextEditingController();
    _secondaryKeyCtrl = TextEditingController();

    _elStability = cfg.elevenLabsStability;
    _elSimilarity = cfg.elevenLabsSimilarityBoost;
    _elStyle = cfg.elevenLabsStyle;
    _elSpeed = cfg.elevenLabsSpeed;
    _elSpeakerBoost = cfg.elevenLabsUseSpeakerBoost;
    _elFormat = cfg.elevenLabsOutputFormat;
    _elSttTagEvents = cfg.elevenLabsSttTagAudioEvents;
    _elSttDiarize = cfg.elevenLabsSttDiarize;
    _elVoiceName = cfg.elevenLabsVoiceName;

    _reuseTtsKey = cfg.openaiTtsReuseLlmKey;
    _reuseSttKey = cfg.openaiSttReuseLlmKey;
    _openAiTtsSpeed = cfg.openaiTtsSpeed;
    _openAiTtsFormat = cfg.openaiTtsFormat;
    _openAiSttTemp = cfg.openaiSttTemperature;

    _googleReuseKey = cfg.googleSpeechReuseLlmKey;
    _timeoutSeconds = cfg.timeoutSeconds;

    switch (widget.provider) {
      case 'elevenlabs':
        _baseUrlCtrl = TextEditingController(text: cfg.elevenLabsBaseUrl);
        _secondaryBaseUrlCtrl = TextEditingController();
        _ttsModelCtrl = TextEditingController(text: cfg.elevenLabsTtsModel);
        _sttModelCtrl = TextEditingController(text: cfg.elevenLabsSttModel);
        _voiceCtrl = TextEditingController(text: cfg.elevenLabsVoiceId);
        _instructionsCtrl = TextEditingController();
        _sttPromptCtrl = TextEditingController();
      case 'openai':
        _baseUrlCtrl = TextEditingController(text: cfg.openaiTtsBaseUrl);
        _secondaryBaseUrlCtrl = TextEditingController(text: cfg.openaiSttBaseUrl);
        _ttsModelCtrl = TextEditingController(text: cfg.openaiTtsModel);
        _sttModelCtrl = TextEditingController(text: cfg.openaiSttModel);
        _voiceCtrl = TextEditingController(text: cfg.openaiTtsVoice);
        _instructionsCtrl = TextEditingController(text: cfg.openaiTtsInstructions);
        _sttPromptCtrl = TextEditingController(text: cfg.openaiSttPrompt);
      default: // google
        _baseUrlCtrl = TextEditingController(text: cfg.googleSpeechBaseUrl);
        _secondaryBaseUrlCtrl = TextEditingController();
        _ttsModelCtrl = TextEditingController(text: cfg.googleTtsModel);
        _sttModelCtrl = TextEditingController(text: cfg.googleSttModel);
        _voiceCtrl = TextEditingController(text: cfg.googleTtsVoiceName);
        _instructionsCtrl = TextEditingController(text: cfg.googleTtsStylePrompt);
        _sttPromptCtrl = TextEditingController();
    }

    _loadKeyFlags();
  }

  Future<void> _loadKeyFlags() async {
    final notifier = ref.read(cloudSpeechConfigProvider.notifier);
    if (widget.provider == 'elevenlabs') {
      final k = await notifier.readSpeechApiKey(SecretKeys.elevenLabs);
      if (mounted) setState(() => _hasPrimaryKey = k.isNotEmpty);
    } else if (widget.provider == 'openai') {
      final k1 = await notifier.readSpeechApiKey(SecretKeys.openaiTts);
      final k2 = await notifier.readSpeechApiKey(SecretKeys.openaiStt);
      if (mounted) {
        setState(() {
          _hasPrimaryKey = k1.isNotEmpty;
          _hasSecondaryKey = k2.isNotEmpty;
        });
      }
    } else {
      final k = await notifier.readSpeechApiKey(SecretKeys.googleSpeech);
      if (mounted) setState(() => _hasPrimaryKey = k.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _primaryKeyCtrl.dispose();
    _secondaryKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _secondaryBaseUrlCtrl.dispose();
    _ttsModelCtrl.dispose();
    _sttModelCtrl.dispose();
    _voiceCtrl.dispose();
    _instructionsCtrl.dispose();
    _sttPromptCtrl.dispose();
    super.dispose();
  }

  CloudSpeechConfig _buildDraftConfig() {
    final base = ref.read(cloudSpeechConfigProvider);
    switch (widget.provider) {
      case 'elevenlabs':
        return base.copyWith(
          elevenLabsBaseUrl: _baseUrlCtrl.text.trim(),
          elevenLabsVoiceId: _voiceCtrl.text.trim(),
          elevenLabsVoiceName: _elVoiceName,
          elevenLabsTtsModel: _ttsModelCtrl.text.trim(),
          elevenLabsStability: _elStability,
          elevenLabsSimilarityBoost: _elSimilarity,
          elevenLabsStyle: _elStyle,
          elevenLabsSpeed: _elSpeed,
          elevenLabsUseSpeakerBoost: _elSpeakerBoost,
          elevenLabsOutputFormat: _elFormat,
          elevenLabsSttModel: _sttModelCtrl.text.trim(),
          elevenLabsSttTagAudioEvents: _elSttTagEvents,
          elevenLabsSttDiarize: _elSttDiarize,
          timeoutSeconds: _timeoutSeconds,
        ).normalized();
      case 'openai':
        return base.copyWith(
          openaiTtsReuseLlmKey: _reuseTtsKey,
          openaiTtsBaseUrl: _baseUrlCtrl.text.trim(),
          openaiTtsModel: _ttsModelCtrl.text.trim(),
          openaiTtsVoice: _voiceCtrl.text.trim(),
          openaiTtsSpeed: _openAiTtsSpeed,
          openaiTtsInstructions: _instructionsCtrl.text.trim(),
          openaiTtsFormat: _openAiTtsFormat,
          openaiSttReuseLlmKey: _reuseSttKey,
          openaiSttBaseUrl: _secondaryBaseUrlCtrl.text.trim(),
          openaiSttModel: _sttModelCtrl.text.trim(),
          openaiSttPrompt: _sttPromptCtrl.text.trim(),
          openaiSttTemperature: _openAiSttTemp,
          timeoutSeconds: _timeoutSeconds,
        ).normalized();
      default:
        return base.copyWith(
          googleSpeechReuseLlmKey: _googleReuseKey,
          googleSpeechBaseUrl: _baseUrlCtrl.text.trim(),
          googleTtsModel: _ttsModelCtrl.text.trim(),
          googleTtsVoiceName: _voiceCtrl.text.trim(),
          googleTtsStylePrompt: _instructionsCtrl.text.trim(),
          googleSttModel: _sttModelCtrl.text.trim(),
          timeoutSeconds: _timeoutSeconds,
        ).normalized();
    }
  }

  Future<String> _resolveDraftTtsKey() async {
    final typed = _primaryKeyCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    // Simpan sementara flag reuse tidak mengubah store, baca resolver notifier.
    return ref
        .read(cloudSpeechConfigProvider.notifier)
        .resolveTtsApiKey(widget.provider);
  }

  Future<void> _loadElevenLabsVoices() async {
    if (_loadingVoices) return;
    final strings = ref.read(appStringsProvider);
    setState(() {
      _loadingVoices = true;
      _statusMsg = null;
    });
    try {
      final key = await _resolveDraftTtsKey();
      final voices = await ref
          .read(genkitCloudClientProvider)
          .fetchElevenLabsVoices(
            apiKey: key,
            baseUrl: _baseUrlCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _accountVoices = voices;
        _statusMsg = '${strings.elevenLabsVoicesLoaded} (${voices.length})';
        _statusIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMsg = strings.speechTestVoiceFailed;
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _loadingVoices = false);
    }
  }

  Future<void> _testVoice() async {
    if (_testingVoice) return;
    final strings = ref.read(appStringsProvider);
    final settings = ref.read(appSettingsProvider);
    setState(() {
      _testingVoice = true;
      _statusMsg = null;
    });
    try {
      final draft = _buildDraftConfig();
      final apiKey = await _resolveDraftTtsKey();
      final ok = await TtsService().speak(
        strings.speechTestVoiceSample,
        backend: widget.provider,
        languageCode: settings.language == AppLanguage.english
            ? 'en-US'
            : 'id-ID',
        cloudConfig: draft,
        apiKey: apiKey,
        cloudClient: ref.read(genkitCloudClientProvider),
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _statusMsg = strings.speechTestVoiceFailed;
          _statusIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _testingVoice = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final strings = ref.read(appStringsProvider);
    if (!isValidBaseUrl(_baseUrlCtrl.text) ||
        !isValidBaseUrl(_secondaryBaseUrlCtrl.text)) {
      setState(() {
        _statusMsg = strings.cloudBaseUrlInvalid;
        _statusIsError = true;
      });
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(cloudSpeechConfigProvider.notifier);
      notifier.save(_buildDraftConfig());

      final primary = _primaryKeyCtrl.text.trim();
      final secondary = _secondaryKeyCtrl.text.trim();
      if (widget.provider == 'elevenlabs' && primary.isNotEmpty) {
        await notifier.saveSpeechApiKey(SecretKeys.elevenLabs, primary);
      } else if (widget.provider == 'openai') {
        if (primary.isNotEmpty) {
          await notifier.saveSpeechApiKey(SecretKeys.openaiTts, primary);
        }
        if (secondary.isNotEmpty) {
          await notifier.saveSpeechApiKey(SecretKeys.openaiStt, secondary);
        }
      } else if (widget.provider == 'google' && primary.isNotEmpty) {
        await notifier.saveSpeechApiKey(SecretKeys.googleSpeech, primary);
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final providerName = switch (widget.provider) {
      'elevenlabs' => strings.speechBackendElevenLabs,
      'openai' => strings.speechBackendOpenAi,
      _ => strings.speechBackendGoogle,
    };

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusSheet),
        ),
        border: Border(top: AppBorders.hairline(context)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              appSheetHandle(context),
              appSheetHeader(
                context,
                title: '${strings.speechCloudConfigTitle} · $providerName',
                closeTooltip: strings.commonClose,
                onClose: () => Navigator.of(context).pop(),
              ),
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.pageGutter,
                    AppSizes.spaceMd,
                    AppSizes.pageGutter,
                    MediaQuery.viewInsetsOf(context).bottom + AppSizes.spaceLg,
                  ),
                  children: [
                    if (widget.provider == 'elevenlabs')
                      ..._buildElevenLabsFields(strings, scheme)
                    else if (widget.provider == 'openai')
                      ..._buildOpenAiFields(strings, scheme)
                    else
                      ..._buildGoogleFields(strings, scheme),
                    const SizedBox(height: AppSizes.spaceSm),
                    _speechSlider(
                      context,
                      label: strings.speechCloudTimeout,
                      value: _timeoutSeconds.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 11,
                      valueText: '${_timeoutSeconds}s',
                      onChanged: (v) => setState(
                        () => _timeoutSeconds = (v / 10).round() * 10,
                      ),
                    ),
                    if (_statusMsg != null) ...[
                      const SizedBox(height: AppSizes.spaceXs),
                      Text(
                        _statusMsg!,
                        style: AppTextStyles.bodySmall(
                          color: _statusIsError
                              ? scheme.error
                              : AppColors.successFor(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.spaceMd),
                    SecondaryButton(
                      label: strings.speechTestVoice,
                      icon: Icons.volume_up_rounded,
                      onPressed: _testingVoice ? null : _testVoice,
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    PrimaryButton(
                      label: strings.settingsSaveChanges,
                      loading: _saving,
                      icon: Icons.check_rounded,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  List<Widget> _buildElevenLabsFields(AppStrings strings, ColorScheme scheme) {
    return [
      TextField(
        controller: _primaryKeyCtrl,
        obscureText: _obscurePrimary,
        decoration: InputDecoration(
          labelText: 'ElevenLabs ${strings.cloudApiKey}',
          hintText: _hasPrimaryKey
              ? strings.cloudApiKeySavedHint
              : strings.cloudApiKeyHint,
          prefixIcon: const Icon(Icons.key_rounded),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePrimary
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscurePrimary = !_obscurePrimary),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _baseUrlCtrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: strings.cloudBaseUrl,
          hintText: kDefaultElevenLabsBaseUrl,
          prefixIcon: const Icon(Icons.link_rounded),
        ),
      ),
      const SizedBox(height: AppSizes.spaceMd),
      TextField(
        controller: _voiceCtrl,
        decoration: InputDecoration(
          labelText: strings.elevenLabsVoiceId,
          hintText: strings.elevenLabsVoiceIdHint,
          prefixIcon: const Icon(Icons.record_voice_over_rounded),
        ),
      ),
      const SizedBox(height: AppSizes.spaceXs),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _loadingVoices ? null : _loadElevenLabsVoices,
          icon: _loadingVoices
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.library_music_outlined, size: 18),
          label: Text(strings.elevenLabsLoadVoices),
        ),
      ),
      const SizedBox(height: AppSizes.spaceXs),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in _accountVoices)
            ChoiceChip(
              label: Text(v.name),
              selected: _voiceCtrl.text.trim() == v.voiceId,
              onSelected: (_) => setState(() {
                _voiceCtrl.text = v.voiceId;
                _elVoiceName = v.name;
              }),
            ),
          for (final preset in kElevenLabsVoicePresets)
            ChoiceChip(
              label: Text('${preset.name} · ${preset.styleTag}'),
              selected: _voiceCtrl.text.trim() == preset.voiceId,
              onSelected: (_) => setState(() {
                _voiceCtrl.text = preset.voiceId;
                _elVoiceName = preset.name;
              }),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _ttsModelCtrl,
        decoration: InputDecoration(
          labelText: strings.settingsVoiceTtsModel,
          hintText: 'eleven_multilingual_v2',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in kElevenLabsTtsModels)
            ChoiceChip(
              label: Text(m),
              selected: _ttsModelCtrl.text.trim() == m,
              onSelected: (_) => setState(() => _ttsModelCtrl.text = m),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceSm),
      _speechSlider(
        context,
        label: strings.elevenLabsStability,
        value: _elStability,
        min: 0.0,
        max: 1.0,
        divisions: 20,
        valueText: _elStability.toStringAsFixed(2),
        onChanged: (v) => setState(() => _elStability = v),
      ),
      _speechSlider(
        context,
        label: strings.elevenLabsSimilarity,
        value: _elSimilarity,
        min: 0.0,
        max: 1.0,
        divisions: 20,
        valueText: _elSimilarity.toStringAsFixed(2),
        onChanged: (v) => setState(() => _elSimilarity = v),
      ),
      _speechSlider(
        context,
        label: strings.elevenLabsStyle,
        value: _elStyle,
        min: 0.0,
        max: 1.0,
        divisions: 20,
        valueText: _elStyle.toStringAsFixed(2),
        onChanged: (v) => setState(() => _elStyle = v),
      ),
      _speechSlider(
        context,
        label: strings.elevenLabsSpeed,
        value: _elSpeed,
        min: 0.7,
        max: 1.2,
        divisions: 10,
        valueText: '${_elSpeed.toStringAsFixed(2)}x',
        onChanged: (v) => setState(() => _elSpeed = v),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.elevenLabsSpeakerBoost),
        value: _elSpeakerBoost,
        onChanged: (v) => setState(() => _elSpeakerBoost = v),
      ),
      Text(
        strings.elevenLabsOutputFormat,
        style: AppTextStyles.bodySmall(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final fmt in kElevenLabsOutputFormats)
            ChoiceChip(
              label: Text(fmt),
              selected: _elFormat == fmt,
              onSelected: (_) => setState(() => _elFormat = fmt),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceMd),
      TextField(
        controller: _sttModelCtrl,
        decoration: InputDecoration(
          labelText: strings.settingsVoiceSttModel,
          hintText: 'scribe_v2',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in kElevenLabsSttModels)
            ChoiceChip(
              label: Text(m),
              selected: _sttModelCtrl.text.trim() == m,
              onSelected: (_) => setState(() => _sttModelCtrl.text = m),
            ),
        ],
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.elevenLabsSttTagEvents),
        value: _elSttTagEvents,
        onChanged: (v) => setState(() => _elSttTagEvents = v),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.elevenLabsSttDiarize),
        value: _elSttDiarize,
        onChanged: (v) => setState(() => _elSttDiarize = v),
      ),
    ];
  }

  List<Widget> _buildOpenAiFields(AppStrings strings, ColorScheme scheme) {
    return [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text('${strings.speechReuseLlmKey} (TTS)'),
        subtitle: Text(
          strings.speechReuseLlmKeyDesc,
          style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
        ),
        value: _reuseTtsKey,
        onChanged: (v) => setState(() => _reuseTtsKey = v),
      ),
      TextField(
        controller: _primaryKeyCtrl,
        obscureText: _obscurePrimary,
        decoration: InputDecoration(
          labelText: 'TTS ${strings.cloudApiKey}',
          hintText: _hasPrimaryKey
              ? strings.cloudApiKeySavedHint
              : strings.cloudApiKeyHint,
          prefixIcon: const Icon(Icons.key_rounded),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePrimary
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscurePrimary = !_obscurePrimary),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _baseUrlCtrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: 'TTS ${strings.cloudBaseUrl}',
          hintText: 'https://api.openai.com/v1',
          prefixIcon: const Icon(Icons.link_rounded),
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _ttsModelCtrl,
        decoration: InputDecoration(
          labelText: strings.settingsVoiceTtsModel,
          hintText: 'gpt-4o-mini-tts',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in kOpenAiTtsModels)
            ChoiceChip(
              label: Text(m),
              selected: _ttsModelCtrl.text.trim() == m,
              onSelected: (_) => setState(() => _ttsModelCtrl.text = m),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _voiceCtrl,
        decoration: InputDecoration(
          labelText: strings.openAiTtsVoice,
          hintText: 'coral',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in kOpenAiTtsVoices)
            ChoiceChip(
              label: Text(v),
              selected: _voiceCtrl.text.trim() == v,
              onSelected: (_) => setState(() => _voiceCtrl.text = v),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceSm),
      _speechSlider(
        context,
        label: strings.elevenLabsSpeed,
        value: _openAiTtsSpeed,
        min: 0.25,
        max: 4.0,
        divisions: 15,
        valueText: '${_openAiTtsSpeed.toStringAsFixed(2)}x',
        onChanged: (v) => setState(() => _openAiTtsSpeed = v),
      ),
      TextField(
        controller: _instructionsCtrl,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: strings.openAiTtsInstructions,
          hintText: strings.openAiTtsInstructionsHint,
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final fmt in kOpenAiTtsFormats)
            ChoiceChip(
              label: Text(fmt.toUpperCase()),
              selected: _openAiTtsFormat == fmt,
              onSelected: (_) => setState(() => _openAiTtsFormat = fmt),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceMd),
      Divider(height: 1, color: scheme.outlineVariant),
      const SizedBox(height: AppSizes.spaceSm),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text('${strings.speechReuseLlmKey} (STT)'),
        value: _reuseSttKey,
        onChanged: (v) => setState(() => _reuseSttKey = v),
      ),
      TextField(
        controller: _secondaryKeyCtrl,
        obscureText: _obscureSecondary,
        decoration: InputDecoration(
          labelText: 'STT ${strings.cloudApiKey}',
          hintText: _hasSecondaryKey
              ? strings.cloudApiKeySavedHint
              : strings.cloudApiKeyHint,
          prefixIcon: const Icon(Icons.key_rounded),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSecondary
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () =>
                setState(() => _obscureSecondary = !_obscureSecondary),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _secondaryBaseUrlCtrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: 'STT ${strings.cloudBaseUrl}',
          hintText: 'https://api.openai.com/v1',
          prefixIcon: const Icon(Icons.link_rounded),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _secondaryBaseUrlCtrl.text = kGroqOpenAiBaseUrl;
            _sttModelCtrl.text = 'whisper-large-v3-turbo';
          }),
          icon: const Icon(Icons.flash_on_rounded, size: 16),
          label: Text(strings.openAiSttGroqPreset),
        ),
      ),
      TextField(
        controller: _sttModelCtrl,
        decoration: InputDecoration(
          labelText: strings.settingsVoiceSttModel,
          hintText: 'gpt-4o-mini-transcribe',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in kOpenAiSttModels)
            ChoiceChip(
              label: Text(m),
              selected: _sttModelCtrl.text.trim() == m,
              onSelected: (_) => setState(() => _sttModelCtrl.text = m),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _sttPromptCtrl,
        decoration: InputDecoration(
          labelText: strings.openAiSttPrompt,
          hintText: strings.openAiSttPromptHint,
        ),
      ),
      const SizedBox(height: AppSizes.spaceXs),
      _speechSlider(
        context,
        label: strings.openAiSttTemperature,
        value: _openAiSttTemp,
        min: 0.0,
        max: 1.0,
        divisions: 10,
        valueText: _openAiSttTemp.toStringAsFixed(1),
        onChanged: (v) => setState(() => _openAiSttTemp = v),
      ),
    ];
  }

  List<Widget> _buildGoogleFields(AppStrings strings, ColorScheme scheme) {
    return [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.speechReuseLlmKey),
        subtitle: Text(
          strings.speechReuseLlmKeyDesc,
          style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
        ),
        value: _googleReuseKey,
        onChanged: (v) => setState(() => _googleReuseKey = v),
      ),
      TextField(
        controller: _primaryKeyCtrl,
        obscureText: _obscurePrimary,
        decoration: InputDecoration(
          labelText: 'Google ${strings.cloudApiKey}',
          hintText: _hasPrimaryKey
              ? strings.cloudApiKeySavedHint
              : strings.cloudApiKeyHint,
          prefixIcon: const Icon(Icons.key_rounded),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePrimary
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscurePrimary = !_obscurePrimary),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _baseUrlCtrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: strings.cloudBaseUrl,
          hintText: strings.cloudBaseUrlHint,
          prefixIcon: const Icon(Icons.link_rounded),
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _ttsModelCtrl,
        decoration: InputDecoration(
          labelText: strings.settingsVoiceTtsModel,
          hintText: 'gemini-2.5-flash-preview-tts',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in kGoogleTtsModels)
            ChoiceChip(
              label: Text(m),
              selected: _ttsModelCtrl.text.trim() == m,
              onSelected: (_) => setState(() => _ttsModelCtrl.text = m),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _voiceCtrl,
        decoration: InputDecoration(
          labelText: strings.googleTtsVoice,
          hintText: 'Aoede',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in kGoogleTtsVoices.take(12))
            ChoiceChip(
              label: Text(v),
              selected: _voiceCtrl.text.trim() == v,
              onSelected: (_) => setState(() => _voiceCtrl.text = v),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _instructionsCtrl,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: strings.googleTtsStylePrompt,
          hintText: strings.googleTtsStylePromptHint,
        ),
      ),
      const SizedBox(height: AppSizes.spaceSm),
      TextField(
        controller: _sttModelCtrl,
        decoration: InputDecoration(
          labelText: strings.settingsVoiceSttModel,
          hintText: 'gemini-2.5-flash',
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in kGoogleSttModels)
            ChoiceChip(
              label: Text(m),
              selected: _sttModelCtrl.text.trim() == m,
              onSelected: (_) => setState(() => _sttModelCtrl.text = m),
            ),
        ],
      ),
    ];
  }
}

Widget _speechSlider(
  BuildContext context, {
  required String label,
  required double value,
  required double min,
  required double max,
  required int divisions,
  required String valueText,
  required ValueChanged<double> onChanged,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium(color: scheme.onSurface),
            ),
          ),
          Text(
            valueText,
            style: AppTextStyles.caption(
              color: AppColors.primaryDeepFor(context),
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    ],
  );
}

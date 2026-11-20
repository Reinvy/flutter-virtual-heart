// Bottom sheet editor profil & parameter Cloud AI BYOK (Google / Anthropic / OpenAI-compatible).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/components/app_sheet.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/components/sheet_header.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/ai_provider_profile.dart';
import '../../services/ai/ai_provider_controller.dart';
import '../../services/ai/cloud_provider_catalog.dart';
import '../../services/ai/genkit/genkit_cloud_client.dart';
import '../../services/ai/genkit/provider_config_builder.dart';
import '../../services/ai/model_service.dart';
import 'model_error_text.dart';

/// Hasil penyimpanan dari [CloudProviderEditorSheet].
class CloudProviderEditorResult {
  final AiProviderProfile profile;
  final bool activated;

  const CloudProviderEditorResult({
    required this.profile,
    required this.activated,
  });
}

/// Membuka sheet tambah/edit profil Cloud BYOK + seluruh parameter generasi & konteks.
Future<CloudProviderEditorResult?> showCloudProviderEditorSheet(
  BuildContext context, {
  required AiProviderProfile initialProfile,
  bool isNew = false,
}) {
  return showAppSheet<CloudProviderEditorResult>(
    context,
    child: CloudProviderEditorSheet(
      initialProfile: initialProfile,
      isNew: isNew,
    ),
  );
}

class CloudProviderEditorSheet extends ConsumerStatefulWidget {
  const CloudProviderEditorSheet({
    super.key,
    required this.initialProfile,
    this.isNew = false,
  });

  final AiProviderProfile initialProfile;
  final bool isNew;

  @override
  ConsumerState<CloudProviderEditorSheet> createState() =>
      _CloudProviderEditorSheetState();
}

class _CloudProviderEditorSheetState
    extends ConsumerState<CloudProviderEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _modelIdCtrl;
  late final TextEditingController _headersCtrl;
  late final TextEditingController _topKCtrl;
  late final TextEditingController _thinkingBudgetCtrl;
  late final TextEditingController _stopSeqCtrl;
  late final TextEditingController _seedCtrl;
  late final TextEditingController _customSystemCtrl;
  late final TextEditingController _bgModelCtrl;

  late LlmProviderType _providerType;
  late bool _stripStreamOptions;
  late bool _useTemperature;
  late double _temperature;
  late bool _useTopP;
  late double _topP;
  late int _maxOutputTokens;
  late bool _usePresencePenalty;
  late double _presencePenalty;
  late bool _useFrequencyPenalty;
  late double _frequencyPenalty;
  late String _reasoningEffort;
  late String _geminiSafetyLevel;
  late int _maxHistoryMessages;
  late int _maxMemoryFacts;
  late int _maxInputChars;
  late int _maxPromptChars;
  late bool _enforceShortReply;
  late int _timeoutSeconds;
  late bool _enableBackgroundTasks;

  bool _obscureApiKey = true;
  bool _hasExistingKey = false;
  bool _testing = false;
  bool _fetchingModels = false;
  bool _saving = false;
  ConnectionTestResult? _testResult;
  List<String> _discoveredModels = const [];
  String? _inlineNotice;
  bool _inlineNoticeIsError = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile.normalized();
    _nameCtrl = TextEditingController(text: p.name);
    _baseUrlCtrl = TextEditingController(text: p.baseUrl);
    _apiKeyCtrl = TextEditingController();
    _modelIdCtrl = TextEditingController(text: p.modelId);
    _headersCtrl = TextEditingController(text: p.customHeadersJson);
    _topKCtrl = TextEditingController(text: p.topK?.toString() ?? '');
    _thinkingBudgetCtrl = TextEditingController(
      text: p.thinkingBudgetTokens?.toString() ?? '',
    );
    _stopSeqCtrl = TextEditingController(text: p.stopSequences.join(', '));
    _seedCtrl = TextEditingController(text: p.seed?.toString() ?? '');
    _customSystemCtrl = TextEditingController(text: p.customSystemPrompt);
    _bgModelCtrl = TextEditingController(text: p.backgroundModelId);

    _providerType = p.providerType;
    _stripStreamOptions = p.stripStreamOptions;
    _useTemperature = p.temperature != null;
    _temperature = p.temperature ?? (_providerType == LlmProviderType.anthropic ? 0.8 : 0.9);
    _useTopP = p.topP != null;
    _topP = p.topP ?? 0.95;
    _maxOutputTokens = p.maxOutputTokens <= 0 ? 2048 : p.maxOutputTokens;
    _usePresencePenalty = p.presencePenalty != null;
    _presencePenalty = p.presencePenalty ?? 0.0;
    _useFrequencyPenalty = p.frequencyPenalty != null;
    _frequencyPenalty = p.frequencyPenalty ?? 0.0;
    _reasoningEffort = p.reasoningEffort;
    _geminiSafetyLevel = p.geminiSafetyLevel;
    _maxHistoryMessages = p.maxHistoryMessages;
    _maxMemoryFacts = p.maxMemoryFacts;
    _maxInputChars = p.maxInputChars;
    _maxPromptChars = p.maxPromptChars;
    _enforceShortReply = p.enforceShortReply;
    _timeoutSeconds = p.timeoutSeconds;
    _enableBackgroundTasks = p.enableBackgroundTasks;

    if (!widget.isNew && p.profileKey.isNotEmpty) {
      _loadExistingKeyStatus(p);
    }
  }

  Future<void> _loadExistingKeyStatus(AiProviderProfile profile) async {
    final key = await ref
        .read(aiProviderProfilesProvider.notifier)
        .readApiKey(profile);
    if (!mounted) return;
    setState(() => _hasExistingKey = key.isNotEmpty);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelIdCtrl.dispose();
    _headersCtrl.dispose();
    _topKCtrl.dispose();
    _thinkingBudgetCtrl.dispose();
    _stopSeqCtrl.dispose();
    _seedCtrl.dispose();
    _customSystemCtrl.dispose();
    _bgModelCtrl.dispose();
    super.dispose();
  }

  AiProviderProfile _buildDraftProfile() {
    final stopList = _stopSeqCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final topK = int.tryParse(_topKCtrl.text.trim());
    final thinkingBudget = int.tryParse(_thinkingBudgetCtrl.text.trim());
    final seed = int.tryParse(_seedCtrl.text.trim());

    return widget.initialProfile.copyWith(
      name: _nameCtrl.text.trim(),
      providerType: _providerType,
      baseUrl: _baseUrlCtrl.text.trim(),
      modelId: _modelIdCtrl.text.trim(),
      customHeadersJson: _headersCtrl.text.trim(),
      stripStreamOptions: _stripStreamOptions,
      temperature: _useTemperature ? _temperature : null,
      clearTemperature: !_useTemperature,
      topP: _useTopP ? _topP : null,
      clearTopP: !_useTopP,
      topK: topK,
      clearTopK: topK == null,
      maxOutputTokens: _maxOutputTokens,
      presencePenalty: _usePresencePenalty ? _presencePenalty : null,
      clearPresencePenalty: !_usePresencePenalty,
      frequencyPenalty: _useFrequencyPenalty ? _frequencyPenalty : null,
      clearFrequencyPenalty: !_useFrequencyPenalty,
      stopSequences: stopList,
      seed: seed,
      clearSeed: seed == null,
      reasoningEffort: _reasoningEffort,
      thinkingBudgetTokens: thinkingBudget,
      clearThinkingBudgetTokens: thinkingBudget == null,
      geminiSafetyLevel: _geminiSafetyLevel,
      maxHistoryMessages: _maxHistoryMessages,
      maxMemoryFacts: _maxMemoryFacts,
      maxInputChars: _maxInputChars,
      maxPromptChars: _maxPromptChars,
      enforceShortReply: _enforceShortReply,
      customSystemPrompt: _customSystemCtrl.text.trim(),
      timeoutSeconds: _timeoutSeconds,
      enableBackgroundTasks: _enableBackgroundTasks,
      backgroundModelId: _bgModelCtrl.text.trim(),
    ).normalized();
  }

  Future<String> _resolveEffectiveApiKey() async {
    final typed = _apiKeyCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    if (_hasExistingKey && widget.initialProfile.profileKey.isNotEmpty) {
      return ref
          .read(aiProviderProfilesProvider.notifier)
          .readApiKey(widget.initialProfile);
    }
    return '';
  }

  void _resetParametersToDefaults() {
    setState(() {
      _useTemperature = true;
      _temperature = _providerType == LlmProviderType.anthropic ? 0.8 : 0.9;
      _useTopP = false;
      _topP = 0.95;
      _topKCtrl.clear();
      _maxOutputTokens = 2048;
      _usePresencePenalty = false;
      _presencePenalty = 0.0;
      _useFrequencyPenalty = false;
      _frequencyPenalty = 0.0;
      _reasoningEffort = '';
      _thinkingBudgetCtrl.clear();
      _geminiSafetyLevel = 'default';
      _stopSeqCtrl.clear();
      _seedCtrl.clear();
      _stripStreamOptions = widget.initialProfile.presetId == 'ollama';
      _maxHistoryMessages = 60;
      _maxMemoryFacts = 40;
      _maxInputChars = 12000;
      _maxPromptChars = 48000;
      _enforceShortReply = false;
      _customSystemCtrl.clear();
      _timeoutSeconds = 60;
      _enableBackgroundTasks = true;
      _bgModelCtrl.clear();
    });
  }

  Future<void> _fetchModels() async {
    if (_fetchingModels) return;
    final strings = ref.read(appStringsProvider);
    setState(() {
      _fetchingModels = true;
      _inlineNotice = null;
    });
    try {
      final apiKey = await _resolveEffectiveApiKey();
      final draft = _buildDraftProfile();
      final models = await ref
          .read(genkitCloudClientProvider)
          .fetchAvailableModels(
            providerType: draft.providerType,
            apiKey: apiKey,
            baseUrl: draft.baseUrl,
            headers: draft.parsedCustomHeaders(),
          );
      if (!mounted) return;
      setState(() {
        _discoveredModels = models;
        _inlineNotice = models.isNotEmpty
            ? '${strings.cloudModelsLoaded} (${models.length})'
            : strings.cloudModelsLoadFailed;
        _inlineNoticeIsError = models.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inlineNotice = strings.cloudModelsLoadFailed;
        _inlineNoticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  Future<void> _testConnection() async {
    if (_testing) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final apiKey = await _resolveEffectiveApiKey();
      final draft = _buildDraftProfile();
      final res = await ref
          .read(genkitCloudClientProvider)
          .testConnection(profile: draft, apiKey: apiKey);
      if (!mounted) return;
      setState(() => _testResult = res);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save({required bool activate}) async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final strings = ref.read(appStringsProvider);
    final draft = _buildDraftProfile();
    final typedKey = _apiKeyCtrl.text.trim();
    final effectiveKey = await _resolveEffectiveApiKey();
    final allowsBlank =
        draft.providerType == LlmProviderType.openai &&
        draft.isLocalNetworkBaseUrl;

    if (effectiveKey.isEmpty && !allowsBlank) {
      if (!mounted) return;
      setState(() {
        _inlineNotice = strings.cloudApiKeyRequired;
        _inlineNoticeIsError = true;
      });
      return;
    }

    setState(() => _saving = true);
    try {
      final keyArg = typedKey.isNotEmpty
          ? typedKey
          : (widget.isNew ? '' : null);
      if (activate) {
        final ok = await ref
            .read(modelServiceProvider.notifier)
            .activateCloudProfile(draft, apiKey: keyArg);
        if (!mounted) return;
        if (!ok) {
          setState(() {
            _inlineNotice = strings.modelErrorAuth;
            _inlineNoticeIsError = true;
          });
          return;
        }
        final active = ref.read(activeCloudProfileProvider) ?? draft;
        Navigator.of(context).pop(
          CloudProviderEditorResult(profile: active, activated: true),
        );
      } else {
        final saved = await ref
            .read(aiProviderProfilesProvider.notifier)
            .saveProfile(draft, apiKey: keyArg);
        if (!mounted) return;
        Navigator.of(context).pop(
          CloudProviderEditorResult(profile: saved, activated: false),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final maxTemp = _providerType == LlmProviderType.anthropic ? 1.0 : 2.0;
    final clampedTemp = _temperature.clamp(0.0, maxTemp).toDouble();

    final suggestions = <String>{
      ..._discoveredModels.take(12),
      ...?cloudPresetById(widget.initialProfile.presetId)?.suggestedModels,
      ...suggestedModelsForType(_providerType),
    }.toList();

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
          initialChildSize: 0.9,
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
                title: widget.isNew
                    ? strings.cloudNewProfile
                    : strings.cloudEditProfile,
                closeTooltip: strings.commonClose,
                onClose: () => Navigator.of(context).pop(),
              ),
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.pageGutter,
                      AppSizes.spaceMd,
                      AppSizes.pageGutter,
                      MediaQuery.viewInsetsOf(context).bottom + AppSizes.spaceLg,
                    ),
                    children: [
                      _sectionTitle(context, strings.cloudSectionConnection),
                      const SizedBox(height: AppSizes.spaceSm),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: strings.cloudProfileName,
                          hintText: strings.cloudProfileNameHint,
                          prefixIcon: const Icon(Icons.label_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceSm),
                      _fieldLabel(context, strings.cloudProviderProtocol),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSizes.spaceXs,
                        runSpacing: AppSizes.spaceXs,
                        children: [
                          for (final type in LlmProviderType.values)
                            ChoiceChip(
                              label: Text(_protocolLabel(strings, type)),
                              selected: _providerType == type,
                              onSelected: (selected) {
                                if (!selected) return;
                                setState(() {
                                  _providerType = type;
                                  if (type == LlmProviderType.anthropic &&
                                      _temperature > 1.0) {
                                    _temperature = 1.0;
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spaceSm),
                      TextFormField(
                        controller: _baseUrlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: strings.cloudBaseUrl,
                          hintText: strings.cloudBaseUrlHint,
                          prefixIcon: const Icon(Icons.link_rounded),
                        ),
                        validator: (val) => isValidBaseUrl(val ?? '')
                            ? null
                            : strings.cloudBaseUrlInvalid,
                      ),
                      const SizedBox(height: AppSizes.spaceSm),
                      TextFormField(
                        controller: _apiKeyCtrl,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          labelText: strings.cloudApiKey,
                          hintText: _hasExistingKey
                              ? strings.cloudApiKeySavedHint
                              : (AiProviderProfile.isLocalNetworkUrl(
                                        _baseUrlCtrl.text,
                                      )
                                    ? strings.cloudApiKeyOptionalLocal
                                    : strings.cloudApiKeyHint),
                          prefixIcon: const Icon(Icons.key_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureApiKey
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureApiKey = !_obscureApiKey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceSm),
                      TextFormField(
                        controller: _modelIdCtrl,
                        decoration: InputDecoration(
                          labelText: strings.cloudModelId,
                          hintText: strings.cloudModelIdHint,
                          prefixIcon: const Icon(
                            Icons.smart_toy_outlined,
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? strings.cloudModelIdRequired
                            : null,
                      ),
                      const SizedBox(height: AppSizes.spaceXs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _fetchingModels ? null : _fetchModels,
                          icon: _fetchingModels
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            _fetchingModels
                                ? strings.cloudFetchingModels
                                : strings.cloudFetchModels,
                          ),
                        ),
                      ),
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.spaceXs),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final model in suggestions.take(8))
                              ActionChip(
                                label: Text(
                                  model,
                                  style: AppTextStyles.caption(
                                    color: _modelIdCtrl.text.trim() == model
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurface,
                                  ),
                                ),
                                backgroundColor: _modelIdCtrl.text.trim() == model
                                    ? scheme.primaryContainer
                                    : scheme.surfaceContainerLow,
                                onPressed: () => setState(
                                  () => _modelIdCtrl.text = model,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSizes.spaceSm),
                      TextFormField(
                        controller: _headersCtrl,
                        decoration: InputDecoration(
                          labelText: strings.cloudCustomHeaders,
                          hintText: strings.cloudCustomHeadersHint,
                          prefixIcon: const Icon(Icons.http_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceSm),
                      SecondaryButton(
                        label: _testing
                            ? strings.cloudTestingConnection
                            : strings.cloudTestConnection,
                        icon: Icons.wifi_tethering_rounded,
                        onPressed: _testing ? null : _testConnection,
                      ),
                      if (_testResult != null) ...[
                        const SizedBox(height: AppSizes.spaceXs),
                        _TestResultBanner(
                          result: _testResult!,
                          strings: strings,
                        ),
                      ],
                      if (_inlineNotice != null) ...[
                        const SizedBox(height: AppSizes.spaceXs),
                        Text(
                          _inlineNotice!,
                          style: AppTextStyles.bodySmall(
                            color: _inlineNoticeIsError
                                ? scheme.error
                                : AppColors.successFor(context),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSizes.spaceLg),
                      Row(
                        children: [
                          Expanded(
                            child: _sectionTitle(
                              context,
                              strings.cloudSectionGeneration,
                            ),
                          ),
                          TextButton(
                            onPressed: _resetParametersToDefaults,
                            child: Text(strings.cloudParametersReset),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spaceXs),
                      _OptionalSliderRow(
                        label: strings.cloudParamTemperature,
                        enabled: _useTemperature,
                        value: clampedTemp,
                        min: 0.0,
                        max: maxTemp,
                        divisions: (maxTemp * 20).round(),
                        valueText: _useTemperature
                            ? clampedTemp.toStringAsFixed(2)
                            : strings.cloudParamAuto,
                        onToggle: (v) => setState(() => _useTemperature = v),
                        onChanged: (v) => setState(() => _temperature = v),
                      ),
                      _OptionalSliderRow(
                        label: strings.cloudParamTopP,
                        enabled: _useTopP,
                        value: _topP,
                        min: 0.05,
                        max: 1.0,
                        divisions: 19,
                        valueText: _useTopP
                            ? _topP.toStringAsFixed(2)
                            : strings.cloudParamAuto,
                        onToggle: (v) => setState(() => _useTopP = v),
                        onChanged: (v) => setState(() => _topP = v),
                      ),
                      if (_providerType == LlmProviderType.anthropic &&
                          _useTemperature &&
                          _useTopP)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSizes.spaceXs,
                          ),
                          child: Text(
                            strings.cloudParamAnthropicSamplingNote,
                            style: AppTextStyles.caption(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      _SliderRow(
                        label: strings.cloudParamMaxOutputTokens,
                        value: _maxOutputTokens.toDouble(),
                        min: 256,
                        max: 32768,
                        divisions: 127,
                        valueText: '$_maxOutputTokens',
                        onChanged: (v) => setState(
                          () => _maxOutputTokens = (v / 256).round() * 256,
                        ),
                      ),
                      if (_providerType != LlmProviderType.anthropic) ...[
                        _OptionalSliderRow(
                          label: strings.cloudParamPresencePenalty,
                          enabled: _usePresencePenalty,
                          value: _presencePenalty,
                          min: -2.0,
                          max: 2.0,
                          divisions: 40,
                          valueText: _usePresencePenalty
                              ? _presencePenalty.toStringAsFixed(1)
                              : strings.cloudParamAuto,
                          onToggle: (v) =>
                              setState(() => _usePresencePenalty = v),
                          onChanged: (v) =>
                              setState(() => _presencePenalty = v),
                        ),
                        _OptionalSliderRow(
                          label: strings.cloudParamFrequencyPenalty,
                          enabled: _useFrequencyPenalty,
                          value: _frequencyPenalty,
                          min: -2.0,
                          max: 2.0,
                          divisions: 40,
                          valueText: _useFrequencyPenalty
                              ? _frequencyPenalty.toStringAsFixed(1)
                              : strings.cloudParamAuto,
                          onToggle: (v) =>
                              setState(() => _useFrequencyPenalty = v),
                          onChanged: (v) =>
                              setState(() => _frequencyPenalty = v),
                        ),
                      ],
                      if (_providerType != LlmProviderType.openai) ...[
                        const SizedBox(height: AppSizes.spaceXs),
                        TextFormField(
                          controller: _topKCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.cloudParamTopK,
                            hintText: '40',
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.spaceSm),
                      _fieldLabel(context, strings.cloudParamReasoningEffort),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final effort in _effortOptionsFor(_providerType))
                            ChoiceChip(
                              label: Text(
                                effort.isEmpty ? strings.cloudParamAuto : effort,
                              ),
                              selected: _reasoningEffort == effort,
                              onSelected: (s) {
                                if (s) setState(() => _reasoningEffort = effort);
                              },
                            ),
                        ],
                      ),
                      if (_providerType != LlmProviderType.openai) ...[
                        const SizedBox(height: AppSizes.spaceSm),
                        TextFormField(
                          controller: _thinkingBudgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.cloudParamThinkingBudget,
                            hintText: _providerType == LlmProviderType.anthropic
                                ? '2048 (min 1024)'
                                : '0..24576',
                          ),
                        ),
                      ],
                      if (_providerType == LlmProviderType.google) ...[
                        const SizedBox(height: AppSizes.spaceSm),
                        _fieldLabel(context, strings.cloudParamGeminiSafety),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final entry in [
                              ('default', strings.cloudSafetyDefault),
                              ('block_only_high', strings.cloudSafetyBlockOnlyHigh),
                              ('block_none', strings.cloudSafetyBlockNone),
                            ])
                              ChoiceChip(
                                label: Text(entry.$2),
                                selected: _geminiSafetyLevel == entry.$1,
                                onSelected: (s) {
                                  if (s) {
                                    setState(() => _geminiSafetyLevel = entry.$1);
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSizes.spaceSm),
                      TextFormField(
                        controller: _stopSeqCtrl,
                        decoration: InputDecoration(
                          labelText: strings.cloudParamStopSequences,
                          hintText: strings.cloudParamStopSequencesHint,
                        ),
                      ),
                      if (_providerType != LlmProviderType.anthropic) ...[
                        const SizedBox(height: AppSizes.spaceSm),
                        TextFormField(
                          controller: _seedCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.cloudParamSeed,
                          ),
                        ),
                      ],
                      if (_providerType == LlmProviderType.openai) ...[
                        const SizedBox(height: AppSizes.spaceXs),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            strings.cloudParamStripStreamOptions,
                            style: AppTextStyles.settingsLabel(
                              color: scheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            strings.cloudParamStripStreamOptionsDesc,
                            style: AppTextStyles.caption(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          value: _stripStreamOptions,
                          onChanged: (v) =>
                              setState(() => _stripStreamOptions = v),
                        ),
                      ],

                      const SizedBox(height: AppSizes.spaceLg),
                      _sectionTitle(context, strings.cloudSectionContext),
                      const SizedBox(height: AppSizes.spaceXs),
                      _SliderRow(
                        label: strings.cloudParamMaxHistory,
                        value: _maxHistoryMessages.toDouble(),
                        min: 10,
                        max: 200,
                        divisions: 19,
                        valueText: '$_maxHistoryMessages',
                        onChanged: (v) => setState(
                          () => _maxHistoryMessages = (v / 10).round() * 10,
                        ),
                      ),
                      _SliderRow(
                        label: strings.cloudParamMaxMemoryFacts,
                        value: _maxMemoryFacts.toDouble(),
                        min: 5,
                        max: 100,
                        divisions: 19,
                        valueText: '$_maxMemoryFacts',
                        onChanged: (v) => setState(
                          () => _maxMemoryFacts = (v / 5).round() * 5,
                        ),
                      ),
                      _SliderRow(
                        label: strings.cloudParamMaxInputChars,
                        value: _maxInputChars.toDouble(),
                        min: 2000,
                        max: 64000,
                        divisions: 31,
                        valueText: '$_maxInputChars',
                        onChanged: (v) => setState(
                          () => _maxInputChars = (v / 2000).round() * 2000,
                        ),
                      ),
                      _SliderRow(
                        label: strings.cloudParamMaxPromptChars,
                        value: _maxPromptChars.toDouble(),
                        min: 6000,
                        max: 256000,
                        divisions: 50,
                        valueText: '${(_maxPromptChars / 1000).round()}k',
                        onChanged: (v) => setState(
                          () => _maxPromptChars = (v / 5000).round() * 5000,
                        ),
                      ),
                      _SliderRow(
                        label: strings.cloudParamTimeoutSeconds,
                        value: _timeoutSeconds.toDouble(),
                        min: 15,
                        max: 300,
                        divisions: 19,
                        valueText: '${_timeoutSeconds}s',
                        onChanged: (v) => setState(
                          () => _timeoutSeconds = (v / 15).round() * 15,
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          strings.cloudParamEnforceShortReply,
                          style: AppTextStyles.settingsLabel(
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          strings.cloudParamEnforceShortReplyDesc,
                          style: AppTextStyles.caption(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        value: _enforceShortReply,
                        onChanged: (v) =>
                            setState(() => _enforceShortReply = v),
                      ),
                      const SizedBox(height: AppSizes.spaceXs),
                      TextFormField(
                        controller: _customSystemCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: strings.cloudParamCustomSystemPrompt,
                          hintText: strings.cloudParamCustomSystemPromptHint,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceXs),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          strings.cloudParamEnableBackground,
                          style: AppTextStyles.settingsLabel(
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          strings.cloudParamEnableBackgroundDesc,
                          style: AppTextStyles.caption(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        value: _enableBackgroundTasks,
                        onChanged: (v) =>
                            setState(() => _enableBackgroundTasks = v),
                      ),
                      if (_enableBackgroundTasks) ...[
                        const SizedBox(height: AppSizes.spaceXs),
                        TextFormField(
                          controller: _bgModelCtrl,
                          decoration: InputDecoration(
                            labelText: strings.cloudParamBackgroundModel,
                            hintText: strings.cloudParamBackgroundModelHint,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.spaceLg),
                      PrimaryButton(
                        label: strings.cloudSaveAndActivate,
                        loading: _saving,
                        icon: Icons.check_rounded,
                        onPressed: _saving ? null : () => _save(activate: true),
                      ),
                      const SizedBox(height: AppSizes.spaceXs),
                      SecondaryButton(
                        label: strings.cloudSaveOnly,
                        onPressed: _saving ? null : () => _save(activate: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  static List<String> _effortOptionsFor(LlmProviderType type) => switch (type) {
    LlmProviderType.google => const ['', 'none', 'minimal', 'low', 'medium', 'high'],
    LlmProviderType.anthropic => const ['', 'none', 'adaptive', 'low', 'medium', 'high', 'max'],
    LlmProviderType.openai => const ['', 'none', 'minimal', 'low', 'medium', 'high'],
  };

  static String _protocolLabel(AppStrings strings, LlmProviderType type) =>
      switch (type) {
        LlmProviderType.google => strings.cloudProtocolGoogle,
        LlmProviderType.anthropic => strings.cloudProtocolAnthropic,
        LlmProviderType.openai => strings.cloudProtocolOpenAi,
      };
}

Widget _sectionTitle(BuildContext context, String label) {
  return Text(
    label.toUpperCase(),
    style: AppTextStyles.sectionLabel(
      color: AppColors.textSecondaryFor(context),
    ),
  );
}

Widget _fieldLabel(BuildContext context, String label) {
  return Text(
    label,
    style: AppTextStyles.bodySmall(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
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
}

class _OptionalSliderRow extends StatelessWidget {
  const _OptionalSliderRow({
    required this.label,
    required this.enabled,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.onToggle,
    required this.onChanged,
  });

  final String label;
  final bool enabled;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueText;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
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
                color: enabled
                    ? AppColors.primaryDeepFor(context)
                    : scheme.onSurfaceVariant,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Switch.adaptive(value: enabled, onChanged: onToggle),
          ],
        ),
        if (enabled)
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
}

class _TestResultBanner extends StatelessWidget {
  const _TestResultBanner({required this.result, required this.strings});

  final ConnectionTestResult result;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ok = result.ok;
    final accent = ok ? AppColors.successFor(context) : scheme.error;
    final message = ok
        ? strings.cloudTestSuccess(result.latencyMs)
        : modelErrorMessage(strings, classifyModelError(result.error ?? ''));

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceSm),
      decoration: BoxDecoration(
        color: ok ? scheme.surfaceContainerLow : scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: accent, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AppSizes.spaceXs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(
                color: ok ? scheme.onSurface : scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

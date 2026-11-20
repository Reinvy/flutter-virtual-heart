// Fitur Model (FR-04) — layar pilih/ganti model AI Lokal (On-Device) atau Cloud (BYOK via Genkit).
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/design/components/app_icon_badge.dart';
import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/confirm_dialog.dart';
import '../../core/design/components/double_back_exit_scope.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/resonance_mark.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/errors/app_logger.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/ai_provider_profile.dart';
import '../../models/app_settings.dart';
import '../../services/ai/ai_provider_controller.dart';
import '../../services/ai/cloud_provider_catalog.dart';
import '../../services/ai/model_catalog.dart';
import '../../services/ai/model_service.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'cloud_provider_editor_sheet.dart';
import 'model_error_text.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  final _tokenController = TextEditingController();
  late AiMode _tabMode;
  ModelOption? _selected;
  bool _pickingFile = false;
  bool _lastRetryWasFile = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _tabMode = settings.aiMode;
    _selected = _catalogOptionFor(settings.modelVariant);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  static ModelOption? _catalogOptionFor(String fileName) {
    if (fileName.isEmpty) return null;
    for (final option in kModelOptions) {
      if (option.fileName == fileName) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final modelState = ref.watch(modelServiceProvider);
    final status = modelState.value;
    final bool busy = status?.installing ?? false;
    final bool building = modelState.isLoading && !modelState.hasValue && !busy;
    final bool activeLocalReady =
        (status?.ready ?? false) && settings.aiMode == AiMode.local;
    final String activeFile = settings.modelVariant;

    final chosen = _selected ?? _catalogOptionFor(activeFile);
    final isLocalSelectedActive = chosen != null
        ? (activeLocalReady && activeFile == chosen.fileName)
        : activeLocalReady;
    final installTarget = _selected ?? kDefaultModelOption;
    final hasBackRoute =
        GoRouter.maybeOf(context)?.canPop() ?? Navigator.canPop(context);
    final canPopRoute = !busy && hasBackRoute;

    return DoubleBackExitScope(
      canPop: canPopRoute,
      onBackBlocked: () {
        if (busy) {
          _cancel();
          return true;
        }
        return false;
      },
      child: AppScaffold(
        appBar: AppBar(
          leading: hasBackRoute && !busy ? const BackButton() : null,
          title: Text(strings.aiEngineTitle),
        ),
        body: AppContent(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceMd),
            children: [
              _buildHeader(strings),
              const SizedBox(height: AppSizes.spaceMd),
              _buildModeSwitcher(strings, busy: busy),
              const SizedBox(height: AppSizes.spaceLg),
              if (building)
                _buildLoading(strings)
              else if (_tabMode == AiMode.cloud)
                _buildCloudTab(strings, settings)
              else ...[
                _buildModelList(
                  strings,
                  activeLocalReady,
                  activeFile,
                  busy: busy,
                ),
                const SizedBox(height: AppSizes.spaceLg),
                _buildTokenField(strings, busy: busy),
                const SizedBox(height: AppSizes.spaceLg),
                _buildActions(
                  strings,
                  busy: busy,
                  isActive: isLocalSelectedActive,
                  target: installTarget,
                ),
                if (busy) _buildProgress(strings, status?.progress ?? 0),
                if (modelState.hasError && !busy)
                  _buildError(
                    strings,
                    modelState.error!,
                    retryLabel: strings.modelRetry,
                    target: installTarget,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings strings) {
    return Row(
      children: [
        const ResonanceMark(size: 44),
        const SizedBox(width: AppSizes.spaceMd),
        Expanded(
          child: Text(
            strings.aiEngineSubtitle,
            style: AppTextStyles.bodyLarge(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher(AppStrings strings, {required bool busy}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<AiMode>(
        segments: [
          ButtonSegment(
            value: AiMode.local,
            label: Text(strings.aiModeLocal),
            icon: const Icon(Icons.memory_rounded),
          ),
          ButtonSegment(
            value: AiMode.cloud,
            label: Text(strings.aiModeCloud),
            icon: const Icon(Icons.cloud_outlined),
          ),
        ],
        selected: {_tabMode},
        onSelectionChanged: busy
            ? null
            : (selection) {
                if (selection.isEmpty) return;
                setState(() => _tabMode = selection.first);
              },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Cloud BYOK Tab
  // -------------------------------------------------------------------------

  Widget _buildCloudTab(AppStrings strings, AppSettings settings) {
    final scheme = Theme.of(context).colorScheme;
    final profiles = ref.watch(aiProviderProfilesProvider);
    final isCloudMode = settings.aiMode == AiMode.cloud;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSizes.radiusPanel),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIconBadge(icon: Icons.vpn_key_outlined),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.cloudByokBannerTitle,
                      style: AppTextStyles.headingSmall(
                        context,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.cloudByokBannerBody,
                      style: AppTextStyles.bodySmall(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spaceLg),
        Text(
          strings.cloudSavedProfiles.toUpperCase(),
          style: AppTextStyles.sectionLabel(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 10),
        if (profiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.spaceMd),
            decoration: AppBorders.cardDecoration(
              context,
              radius: AppSizes.radiusPanel,
            ),
            child: Text(
              strings.cloudNoProfiles,
              style: AppTextStyles.bodyMedium(color: scheme.onSurfaceVariant),
            ),
          )
        else
          ...profiles.map((profile) {
            final active =
                isCloudMode && settings.activeCloudProfileId == profile.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceXs),
              child: _CloudProfileTile(
                profile: profile,
                active: active,
                strings: strings,
                onActivate: () => _activateCloudProfile(profile),
                onEdit: () => _editCloudProfile(profile),
                onDelete: () => _deleteCloudProfile(profile),
              ),
            );
          }),
        const SizedBox(height: AppSizes.spaceLg),
        Text(
          strings.cloudQuickAddTitle.toUpperCase(),
          style: AppTextStyles.sectionLabel(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: AppSizes.spaceXs,
          runSpacing: AppSizes.spaceXs,
          children: [
            for (final preset in kCloudProviderPresets)
              ActionChip(
                avatar: Icon(
                  _providerIcon(preset.providerType),
                  size: 16,
                  color: AppColors.primaryDeepFor(context),
                ),
                label: Text(preset.displayName),
                onPressed: () => _createFromPreset(preset),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _createFromPreset(CloudProviderPreset preset) async {
    final notifier = ref.read(aiProviderProfilesProvider.notifier);
    final draft = preset.toNewProfile(
      profileKey: notifier.generateProfileKey(preset.id),
    );
    final res = await showCloudProviderEditorSheet(
      context,
      initialProfile: draft,
      isNew: true,
    );
    if (!mounted || res == null) return;
    if (res.activated) _onInstalled();
  }

  Future<void> _editCloudProfile(AiProviderProfile profile) async {
    final res = await showCloudProviderEditorSheet(
      context,
      initialProfile: profile,
      isNew: false,
    );
    if (!mounted || res == null) return;
    if (res.activated) _onInstalled();
  }

  Future<void> _activateCloudProfile(AiProviderProfile profile) async {
    final strings = ref.read(appStringsProvider);
    final ok = await ref
        .read(modelServiceProvider.notifier)
        .activateCloudProfile(profile);
    if (!mounted) return;
    if (ok) {
      _onInstalled();
    } else {
      _snack(strings.modelErrorAuth);
    }
  }

  Future<void> _deleteCloudProfile(AiProviderProfile profile) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.cloudDeleteProfileTitle,
      body: strings.cloudDeleteProfileBody,
      confirmLabel: strings.settingsDelete,
      cancelLabel: strings.commonCancel,
    );
    if (!confirmed || !mounted) return;
    await ref.read(aiProviderProfilesProvider.notifier).deleteProfile(profile.id);
    if (!mounted) return;
    ref.invalidate(modelServiceProvider);
  }

  // -------------------------------------------------------------------------
  // Local On-Device Tab (existing FR-04 preserved)
  // -------------------------------------------------------------------------

  Widget _buildLoading(AppStrings strings) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXl),
      child: Column(
        children: [
          const ResonanceMark(size: 88, animate: true),
          const SizedBox(height: 20),
          Text(
            strings.modelLoadingTitle,
            style: AppTextStyles.headingSmall(context, color: scheme.onSurface),
          ),
          const SizedBox(height: AppSizes.spaceXs),
          Text(
            strings.modelLoadingBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildModelList(
    AppStrings strings,
    bool activeReady,
    String activeFile, {
    required bool busy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.modelAvailable.toUpperCase(),
          style: AppTextStyles.sectionLabel(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 10),
        ...kModelOptions.map(
          (opt) => Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spaceXs),
            child: _ModelTile(
              option: opt,
              selected: _selected?.id == opt.id,
              active: activeReady && activeFile == opt.fileName,
              activeLabel: strings.modelActive,
              hfTokenBadge: strings.modelHfTokenBadge,
              onTap: busy ? null : () => setState(() => _selected = opt),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenField(AppStrings strings, {required bool busy}) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _tokenController,
      enabled: !busy,
      obscureText: true,
      decoration: InputDecoration(
        hintText: strings.modelHfTokenHint,
        prefixIcon: const Icon(Icons.key_rounded),
        helperText: strings.modelHfTokenHelper,
        helperStyle: AppTextStyles.caption(color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildActions(
    AppStrings strings, {
    required bool busy,
    required bool isActive,
    required ModelOption target,
  }) {
    final label = busy
        ? strings.modelDownloading
        : (isActive ? strings.modelActive : strings.modelUse);
    return Column(
      children: [
        PrimaryButton(
          label: label,
          loading: busy,
          icon: isActive ? Icons.check_circle_outline : Icons.download_rounded,
          onPressed: busy || isActive ? null : () => _startDownload(target),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        SecondaryButton(
          label: strings.modelUploadFile,
          icon: Icons.upload_file_rounded,
          onPressed: busy ? null : _pickFile,
        ),
        if (busy)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spaceSm),
            child: GhostButton(
              label: strings.modelCancel,
              color: Theme.of(context).colorScheme.error,
              onPressed: _cancel,
            ),
          ),
      ],
    );
  }

  Widget _buildProgress(AppStrings strings, double progress) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (progress * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        decoration: AppBorders.cardDecoration(
          context,
          radius: AppSizes.radiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.modelProgress,
                    style: AppTextStyles.caption(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (progress > 0)
                  Text(
                    '$pct%',
                    style: AppTextStyles.caption(color: scheme.onSurface)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress.clamp(0, 1) : null,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    AppStrings strings,
    Object error, {
    required String retryLabel,
    required ModelOption target,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final kind = error is ModelException
        ? error.kind
        : classifyModelError(error);
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSizes.radiusPanel),
          border: Border.all(color: scheme.error, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconBadge(
                  icon: Icons.error_outline_rounded,
                  color: scheme.error,
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: Text(
                    strings.modelErrorTitle,
                    style: AppTextStyles.headingSmall(
                      context,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceXs),
            Text(
              modelErrorMessage(strings, kind),
              style: AppTextStyles.bodyMedium(color: scheme.onErrorContainer),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _lastRetryWasFile
                    ? _pickFile
                    : () => _startDownload(target),
                child: Text(
                  retryLabel,
                  style: AppTextStyles.button(color: scheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload(ModelOption option) async {
    _lastRetryWasFile = false;
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) await ModelServiceNotifier.saveHfToken(token);
    if (!mounted) return;
    final ok = await ref
        .read(modelServiceProvider.notifier)
        .installFromNetwork(option, hfToken: token.isNotEmpty ? token : null);
    if (!mounted) return;
    if (ok) _onInstalled();
  }

  Future<void> _cancel() async {
    final strings = ref.read(appStringsProvider);
    await ref.read(modelServiceProvider.notifier).cancelDownload();
    if (!mounted) return;
    _snack(strings.modelCancelledSnack);
  }

  Future<void> _pickFile() async {
    if (_pickingFile) return;
    _pickingFile = true;
    _lastRetryWasFile = true;
    final strings = ref.read(appStringsProvider);
    File? target;
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['litertlm', 'task'],
        dialogTitle: strings.modelUploadFile,
      );
      final sourcePath = picked?.path;
      if (sourcePath == null || !mounted) return;

      final basename = File(sourcePath).uri.pathSegments.last;
      final lower = basename.toLowerCase();
      final isLiteRtl = lower.endsWith('.litertlm');
      if (!isLiteRtl && !lower.endsWith('.task')) {
        _snack(strings.modelFileInvalid);
        return;
      }

      final length = await File(sourcePath).length();
      if (!mounted) return;
      if (length == 0) {
        _snack(strings.modelFileEmpty);
        return;
      }

      final modelType = await _askModelType(strings);
      if (!mounted || modelType == null) return;

      final support = await getApplicationSupportDirectory();
      final uploadDir = Directory('${support.path}/model_uploads');
      await uploadDir.create(recursive: true);
      target = await File(sourcePath).copy('${uploadDir.path}/$basename');
      if (!mounted) return;

      final option = ModelOption(
        id: basename,
        name: basename,
        description: basename,
        fileName: basename,
        url: '',
        fileType: isLiteRtl ? 'litertlm' : 'task',
        modelType: modelType,
        sizeLabel: '',
      );
      final ok = await ref
          .read(modelServiceProvider.notifier)
          .installFromFile(target.path, option);
      if (!mounted) return;
      if (ok) _onInstalled();
    } catch (e) {
      AppLogger.debug('Model file upload failed', e);
      if (mounted) _snack(strings.modelErrorUnknown);
    } finally {
      if (target != null) await _deleteQuietly(target);
      _pickingFile = false;
    }
  }

  Future<String?> _askModelType(AppStrings strings) {
    const families = <String, String>{
      'qwen': 'Qwen 2.5',
      'smollm': 'SmolLM',
      'deepseek': 'DeepSeek R1',
      'gemmaIt': 'Gemma 3',
    };
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(strings.modelTypeTitle),
        children: [
          for (final entry in families.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(entry.key),
              child: Text(entry.value),
            ),
        ],
      ),
    );
  }

  void _onInstalled() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.hub);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static IconData _providerIcon(LlmProviderType type) => switch (type) {
    LlmProviderType.google => Icons.auto_awesome_rounded,
    LlmProviderType.anthropic => Icons.psychology_outlined,
    LlmProviderType.openai => Icons.hub_outlined,
  };
}

class _CloudProfileTile extends StatelessWidget {
  const _CloudProfileTile({
    required this.profile,
    required this.active,
    required this.strings,
    required this.onActivate,
    required this.onEdit,
    required this.onDelete,
  });

  final AiProviderProfile profile;
  final bool active;
  final AppStrings strings;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusPanel);
    final protocolTag = switch (profile.providerType) {
      LlmProviderType.google => 'Google',
      LlmProviderType.anthropic => 'Anthropic',
      LlmProviderType.openai => 'OpenAI',
    };
    final tempText = profile.temperature != null
        ? 'T=${profile.temperature!.toStringAsFixed(1)}'
        : 'T=Auto';
    final summary =
        '$tempText · ${profile.maxOutputTokens} tok · ${profile.maxHistoryMessages} msg';

    return Material(
      color: active ? scheme.surfaceContainerLow : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant,
          width: active ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconBadge(
                  icon: _ModelDownloadScreenState._providerIcon(
                    profile.providerType,
                  ),
                  size: 40,
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            profile.name,
                            style: AppTextStyles.headingSmall(
                              context,
                              color: scheme.onSurface,
                            ),
                          ),
                          _Badge(
                            label: protocolTag,
                            background: scheme.secondaryContainer,
                            foreground: scheme.onSecondaryContainer,
                          ),
                          if (active)
                            _Badge(
                              label: strings.modelActive,
                              background: scheme.primaryContainer,
                              foreground: scheme.onPrimaryContainer,
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.modelId,
                        style: AppTextStyles.bodySmall(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        style: AppTextStyles.caption(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceSm),
            Wrap(
              spacing: AppSizes.spaceXs,
              runSpacing: AppSizes.spaceXs,
              children: [
                FilledButton.tonal(
                  onPressed: active ? null : onActivate,
                  child: Text(active ? strings.modelActive : strings.modelUse),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: Text(strings.cloudParametersTitle),
                ),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  child: Text(strings.settingsDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.option,
    required this.selected,
    required this.active,
    required this.activeLabel,
    required this.hfTokenBadge,
    required this.onTap,
  });

  final ModelOption option;
  final bool selected;
  final bool active;
  final String activeLabel;
  final String hfTokenBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusPanel);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: AppDurations.durationFast,
        curve: AppDurations.curveStandard,
        child: Material(
          color: selected ? scheme.surfaceContainerLow : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceMd),
              child: Row(
                children: [
                  const AppIconBadge(icon: Icons.memory_rounded, size: 40),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSizes.spaceXs,
                          runSpacing: 4,
                          children: [
                            Text(
                              option.name,
                              style: AppTextStyles.headingSmall(
                                context,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (active)
                              _Badge(
                                label: activeLabel,
                                background: scheme.primaryContainer,
                                foreground: scheme.onPrimaryContainer,
                              ),
                            if (option.gated)
                              _Badge(
                                label: hfTokenBadge,
                                background: scheme.secondaryContainer,
                                foreground: scheme.onSecondaryContainer,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spaceXxs),
                        Text(
                          option.description,
                          style: AppTextStyles.bodySmall(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceXs,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusBadge,
                            ),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            option.sizeLabel,
                            style: AppTextStyles.badge(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(label, style: AppTextStyles.badge(color: foreground)),
    );
  }
}

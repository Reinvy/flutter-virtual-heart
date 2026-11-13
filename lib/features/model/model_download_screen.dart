// Fitur Model (FR-04) — layar pilih/ganti model AI (network / upload file).
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/design/components/app_icon_badge.dart';
import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/resonance_mark.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../services/ai/model_catalog.dart';
import '../../services/ai/model_service.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'model_error_text.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  final _tokenController = TextEditingController();
  ModelOption? _selected;

  VoidCallback? _retry;

  @override
  void initState() {
    super.initState();
    _selected = _catalogOptionFor(ref.read(appSettingsProvider).modelVariant);
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
    final bool building = modelState.isLoading && status == null;
    final bool activeReady = status?.ready ?? false;
    final String activeFile = settings.modelVariant;

    final chosen = _selected ?? _catalogOptionFor(activeFile);
    final isActive = chosen != null
        ? (activeReady && activeFile == chosen.fileName)
        : activeReady;
    final installTarget = _selected ?? kDefaultModelOption;

    return AppScaffold(
      appBar: AppBar(
        leading: context.canPop() ? const BackButton() : null,
        title: Text(strings.modelChooseTitle),
      ),
      body: AppContent(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceMd),
          children: [
            _buildHeader(strings),
            const SizedBox(height: AppSizes.spaceLg),
            if (building)
              _buildLoading(strings)
            else ...[
              _buildModelList(strings, activeReady, activeFile),
              const SizedBox(height: AppSizes.spaceLg),
              _buildTokenField(strings),
              const SizedBox(height: AppSizes.spaceLg),
              _buildActions(
                strings,
                busy: busy,
                isActive: isActive,
                target: installTarget,
              ),
              if (busy) _buildProgress(strings, status?.progress ?? 0),
              if (modelState.hasError && !busy)
                _buildError(
                  strings,
                  modelState.error!,
                  retryLabel: strings.modelRetry,
                ),
            ],
          ],
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
            strings.modelChooseSubtitle,
            style: AppTextStyles.bodyLarge(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ),
      ],
    );
  }

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
            style: AppTextStyles.headingSmall(
              context,
              color: scheme.onSurface,
            ),
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
    String activeFile,
  ) {
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
              onTap: () => setState(() => _selected = opt),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenField(AppStrings strings) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _tokenController,
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
                Text(
                  '$pct%',
                  style: AppTextStyles.caption(
                    color: scheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
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
  }) {
    final scheme = Theme.of(context).colorScheme;
    final kind = error is ModelException ? error.kind : classifyModelError(error);
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
                onPressed: _retry,
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

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _startDownload(ModelOption option) async {
    setState(() => _retry = () => _startDownload(option));
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
    setState(() => _retry = _pickFile);
    final strings = ref.read(appStringsProvider);

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

    File? target;
    try {
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
      if (ok) {
        _onInstalled();
      } else {
        await _deleteQuietly(target);
      }
    } catch (e) {
      if (target != null) await _deleteQuietly(target);
      if (mounted) _snack(strings.modelErrorUnknown);
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
    } catch (_) {
      // Pembersihan best-effort; file yatim tidak memblokir alur.
    }
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
  final VoidCallback onTap;

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

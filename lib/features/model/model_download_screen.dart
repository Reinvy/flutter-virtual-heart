// Fitur Model (FR-04) — layar pilih/ganti model AI (network / upload file).
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/components/sakura_background.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../services/ai/model_catalog.dart';
import '../../services/ai/model_service.dart';
import '../settings/settings_controller.dart';
import 'model_error_text.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  final _tokenController = TextEditingController();
  ModelOption? _selected;

  /// Aksi yang dijalankan tombol "Coba Lagi" setelah kegagalan terakhir.
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
    final isActive = chosen != null ? (activeReady && activeFile == chosen.fileName) : activeReady;
    final installTarget = _selected ?? kDefaultModelOption;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const BackButton() : null,
        title: Text(strings.modelChooseTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: SakuraBackground(petals: 8)),
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spaceMd,
                AppSizes.spaceMd,
                AppSizes.spaceMd,
                AppSizes.spaceXl,
              ),
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
                  _buildActions(strings, busy: busy, isActive: isActive, target: installTarget),
                  if (busy) _buildProgress(strings, status?.progress ?? 0),
                  if (modelState.hasError && !busy)
                    _buildError(strings, modelState.error!, retryLabel: strings.modelRetry),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.modelChooseTitle, style: AppTextStyles.headingLarge())
            .animate()
            .fadeIn(duration: 400.ms),
        const SizedBox(height: AppSizes.spaceXs),
        Text(
          strings.modelChooseSubtitle,
          style: AppTextStyles.bodyMedium(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      ],
    );
  }

  Widget _buildLoading(AppStrings strings) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceLg),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSizes.spaceMd),
          Text(strings.modelLoadingTitle, style: AppTextStyles.headingSmall()),
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

  Widget _buildModelList(AppStrings strings, bool activeReady, String activeFile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.modelAvailable,
          style: AppTextStyles.headingSmall(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSizes.spaceSm),
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
        helperStyle: AppTextStyles.moodIndicator(color: scheme.onSurfaceVariant),
        isDense: true,
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
            child: TextButton(
              onPressed: _cancel,
              child: Text(
                strings.modelCancel,
                style: AppTextStyles.button(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgress(AppStrings strings, double progress) {
    final pct = (progress * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${strings.modelProgress} $pct%',
            style: AppTextStyles.moodIndicator(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.spaceXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppStrings strings, Object error, {required String retryLabel}) {
    final scheme = Theme.of(context).colorScheme;
    final kind = error is ModelException ? error.kind : classifyModelError(error);
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: scheme.error),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: Text(
                    strings.modelErrorTitle,
                    style: AppTextStyles.headingSmall(color: scheme.onErrorContainer),
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

    // Salin ke penyimpanan aplikasi: engine mendaftarkan path ini dan harus
    // tetap ada selama model dipakai (path sementara dari picker tidak stabil).
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
      context.go(AppRoutes.chat);
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSizes.spaceXs,
                    runSpacing: 2,
                    children: [
                      Text(
                        option.name,
                        style: AppTextStyles.headingSmall(
                          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                        ),
                      ),
                      if (active)
                        _Badge(
                          label: activeLabel,
                          background: scheme.tertiaryContainer,
                          foreground: scheme.onTertiaryContainer,
                        ),
                      if (option.gated)
                        _Badge(
                          label: hfTokenBadge,
                          background: scheme.secondaryContainer,
                          foreground: scheme.onSecondaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: AppTextStyles.moodIndicator(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            Text(
              option.sizeLabel,
              style: AppTextStyles.settingsLabel(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(label, style: AppTextStyles.timestamp(color: foreground)),
    );
  }
}

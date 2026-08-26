// Fitur Model (FR-04) — layar pilih model AI (network / upload file).
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/components/sakura_background.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../services/ai/model_catalog.dart';
import '../../services/ai/model_service.dart';
import 'model_ready_provider.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  final _tokenController = TextEditingController();
  ModelOption? _selected;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final modelState = ref.watch(modelServiceProvider);
    final isReady = modelState.value?.ready ?? false;

    ref.listen(modelReadyProvider, (_, isReady) {
      if (isReady && context.mounted) context.go(AppRoutes.chat);
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: SakuraBackground(petals: 8)),
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spaceMd,
                AppSizes.spaceLg,
                AppSizes.spaceMd,
                AppSizes.spaceXl,
              ),
              children: [
                _buildHeader(strings),
                const SizedBox(height: AppSizes.spaceLg),
                _buildModelList(strings),
                const SizedBox(height: AppSizes.spaceLg),
                _buildTokenField(strings),
                const SizedBox(height: AppSizes.spaceLg),
                _buildActions(strings, modelState, isReady),
                if (modelState.value?.installing == true ||
                    modelState.isLoading)
                  _buildProgress(strings, modelState.value?.progress ?? 0),
                if (modelState.hasError)
                  _buildError(strings, modelState.error?.toString() ?? ''),
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
        Text(
          strings.modelChooseTitle,
          style: AppTextStyles.headingLarge(),
        ).animate().fadeIn(duration: 400.ms),
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

  Widget _buildModelList(AppStrings strings) {
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
    AppStrings strings,
    AsyncValue<ModelStatus> modelState,
    bool isReady,
  ) {
    final installing = modelState.isLoading ||
        (modelState.value?.installing ?? false);
    final option = _selected ?? kDefaultModelOption;

    return Column(
      children: [
        PrimaryButton(
          label: installing ? strings.modelDownloading : strings.modelDownload,
          loading: installing,
          icon: Icons.download_rounded,
          onPressed: installing || isReady
              ? null
              : () => _startDownload(option),
        ),
        const SizedBox(height: AppSizes.spaceSm),
        SecondaryButton(
          label: strings.modelUploadFile,
          icon: Icons.upload_file_rounded,
          onPressed: installing || isReady ? null : _pickFile,
        ),
        if (installing)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spaceSm),
            child: TextButton(
              onPressed: () =>
                  ref.read(modelServiceProvider.notifier).cancelDownload(),
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

  Widget _buildError(AppStrings strings, String error) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spaceMd),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: AppSizes.spaceSm),
            Expanded(
              child: Text(
                error,
                style: AppTextStyles.bodyMedium(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload(ModelOption option) async {
    final notifier = ref.read(modelServiceProvider.notifier);
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) {
      await ModelServiceNotifier.saveHfToken(token);
    }
    final hfToken = token.isNotEmpty ? token : null;
    await notifier.installFromNetwork(option, hfToken: hfToken);
  }

  Future<void> _pickFile() async {
    final strings = ref.read(appStringsProvider);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['litertlm', 'task', 'bin'],
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null) return;

    final lower = path.toLowerCase();
    final isValid =
        lower.endsWith('.litertlm') || lower.endsWith('.task') || lower.endsWith('.bin');
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.modelFileInvalid)),
        );
      }
      return;
    }

    final option = modelOptionById(File(path).uri.pathSegments.last);
    await ref.read(modelServiceProvider.notifier).installFromFile(path, option);
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ModelOption option;
  final bool selected;
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
                  Row(
                    children: [
                      Text(
                        option.name,
                        style: AppTextStyles.headingSmall(
                          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spaceXs),
                      if (option.gated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            'HF Token',
                            style: AppTextStyles.timestamp(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
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

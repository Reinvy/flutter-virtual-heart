// Fitur Model (FR-04) — layar install model AI.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/components/sakura_background.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../services/ai/model_service.dart';
import 'model_ready_provider.dart';

class ModelDownloadScreen extends ConsumerWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelServiceProvider);
    final strings = ref.watch(appStringsProvider);

    ref.listen(modelReadyProvider, (_, isReady) {
      if (isReady && context.mounted) context.go(AppRoutes.chat);
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: SakuraBackground(petals: 8)),
            modelState.when(
              loading: () => _LoadingBody(strings: strings),
              data: (_) => _LoadingBody(strings: strings),
              error: (error, _) => _ErrorBody(
                strings: strings,
                onRetry: () => ref.read(modelServiceProvider.notifier).reset(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motionOk = !MediaQuery.disableAnimationsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondaryContainer,
              ),
              child: Icon(Icons.favorite, size: 56, color: scheme.secondary),
            ).animate(
              onPlay: motionOk ? (c) => c.repeat(reverse: true) : null,
            ).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.12, 1.12),
              duration: 1000.ms,
              curve: Curves.easeInOut,
            ),
            const SizedBox(height: AppSizes.xl),
            Text(strings.modelLoadingTitle, style: AppTextStyles.headingLarge())
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms),
            const SizedBox(height: AppSizes.sm),
            Text(
              strings.modelLoadingBody,
              style: AppTextStyles.bodyMedium(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
            const SizedBox(height: AppSizes.xxl),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
                minHeight: 6,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            const SizedBox(height: AppSizes.xl),
            _LoadingTips(strings: strings),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback onRetry;
  const _ErrorBody({required this.strings, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.errorContainer,
              ),
              child: Icon(Icons.error_outline, size: 56, color: scheme.error),
            ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.7, 0.7),
              duration: 500.ms,
              curve: Curves.easeOut,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(strings.modelErrorTitle, style: AppTextStyles.headingLarge())
                .animate()
                .fadeIn(duration: 500.ms, delay: 150.ms),
            const SizedBox(height: AppSizes.md),
            Text(
              strings.modelErrorBody,
              style: AppTextStyles.bodyMedium(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
            const SizedBox(height: AppSizes.xxl),
            PrimaryButton(label: strings.modelRetry, onPressed: onRetry)
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _LoadingTips extends StatefulWidget {
  final AppStrings strings;
  const _LoadingTips({required this.strings});

  @override
  State<_LoadingTips> createState() => _LoadingTipsState();
}

class _LoadingTipsState extends State<_LoadingTips> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  Future<void> _cycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) break;
      setState(() => _index = (_index + 1) % 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final tips = [
      strings.modelTip1,
      strings.modelTip2,
      strings.modelTip3,
      strings.modelTip4,
      strings.modelTip5,
    ];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        tips[_index],
        key: ValueKey(_index),
        style: AppTextStyles.moodIndicator(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

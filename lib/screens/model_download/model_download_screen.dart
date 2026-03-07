import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/model_ready_provider.dart';
import '../../providers/router_provider.dart';
import '../../services/ai/model_service.dart';

class ModelDownloadScreen extends ConsumerWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching this provider triggers model initialization.
    final modelState = ref.watch(modelServiceProvider);

    // Navigate to chat as soon as the model signals ready.
    ref.listen(modelReadyProvider, (_, isReady) {
      if (isReady && context.mounted) context.go(AppRoutes.chat);
    });

    return Scaffold(
      body: SafeArea(
        child: modelState.when(
          loading: () => const _LoadingBody(),
          data: (_) => const _LoadingBody(),
          error: (error, _) => _ErrorBody(
            message: error.toString(),
            onRetry: () => ref.read(modelServiceProvider.notifier).reset(),
          ),
        ),
      ),
    );
  }
}

// ── Loading body ──────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing heart
            const Icon(Icons.favorite, size: 72, color: AppColors.heartRed)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .shimmer(duration: 1500.ms, color: AppColors.primary.withAlpha(120)),

            const SizedBox(height: AppSizes.xl),

            Text(
              'Memuat Kecerdasan Buatan',
              style: AppTextStyles.headingLarge(),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

            const SizedBox(height: AppSizes.sm),

            Text(
              'Sedang menyiapkan otak pasangan virtualmu...\nProses ini mungkin memakan 1–2 menit.',
              style: AppTextStyles.bodyMedium(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

            const SizedBox(height: AppSizes.xxl),

            // Indeterminate progress bar with romantic styling
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 600.ms),

            const SizedBox(height: AppSizes.xl),

            // Rotating loading tips
            const _LoadingTips(),
          ],
        ),
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.heartRed)
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: AppSizes.lg),

            Text(
              'Oops, Ada Masalah',
              style: AppTextStyles.headingLarge(),
            ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

            const SizedBox(height: AppSizes.md),

            Text(
              'Gagal memuat model AI. Pastikan perangkatmu memiliki RAM ≥ 4 GB dan coba lagi.',
              style: AppTextStyles.bodyMedium(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

            const SizedBox(height: AppSizes.xxl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
                child: Text('Coba Lagi', style: AppTextStyles.button()),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ── Rotating loading tips ─────────────────────────────────────────────────────

class _LoadingTips extends StatefulWidget {
  const _LoadingTips();

  @override
  State<_LoadingTips> createState() => _LoadingTipsState();
}

class _LoadingTipsState extends State<_LoadingTips> {
  static const _tips = [
    '💕 Pasangan virtualmu sedang belajar tentangmu...',
    '🌸 Mempersiapkan kepribadian yang sempurna untukmu...',
    '✨ AI berjalan sepenuhnya di perangkatmu — privasi terjaga',
    '🔮 Hampir siap untuk menemanimu...',
    '💝 Melatih kemampuan bicara yang hangat dan intim...',
  ];

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
      setState(() => _index = (_index + 1) % _tips.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _tips[_index],
        key: ValueKey(_index),
        style: AppTextStyles.moodIndicator(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

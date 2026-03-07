import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/router_provider.dart';

class AgeGateScreen extends ConsumerWidget {
  const AgeGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: AppColors.primary)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOut),

              const SizedBox(height: AppSizes.lg),

              Text(
                'Verifikasi Usia',
                style: AppTextStyles.headingLarge(),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

              const SizedBox(height: AppSizes.md),

              Text(
                'VirtualHeart hanya untuk pengguna berusia 18 tahun ke atas. '
                'Konten dalam aplikasi ini bersifat dewasa dan romantis.',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

              const SizedBox(height: AppSizes.xxl),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _confirm(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  child: Text('Ya, saya berusia ≥ 18 tahun', style: AppTextStyles.button()),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

              const SizedBox(height: AppSizes.md),

              // Decline button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _decline(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.textSecondary),
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  child: Text(
                    'Tidak, keluar dari aplikasi',
                    style: AppTextStyles.button(color: AppColors.textSecondary),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

              const SizedBox(height: AppSizes.xxl),

              Text(
                'Dengan melanjutkan, kamu menyetujui Syarat & Ketentuan\ndan Kebijakan Privasi VirtualHeart.',
                style: AppTextStyles.timestamp(),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final settings = ref.read(appSettingsProvider);
    settings.isAgeVerified = true;
    ref.read(appSettingsProvider.notifier).save(settings);
    context.go(AppRoutes.onboarding);
  }

  void _decline(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Tidak Dapat Melanjutkan', style: AppTextStyles.headingSmall()),
        content: Text(
          'Aplikasi ini hanya untuk pengguna dewasa (18+). '
          'Kamu tidak dapat menggunakan VirtualHeart.',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: Text('Tutup Aplikasi', style: AppTextStyles.button(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

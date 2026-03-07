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
                'Age Verification',
                style: AppTextStyles.headingLarge(),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

              const SizedBox(height: AppSizes.md),

              Text(
                'VirtualHeart is only for users aged 18 and above. '
                'Content in this app is adult and romantic in nature.',
                style: AppTextStyles.bodyMedium(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
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
                  child: Text('Yes, I am 18 or older', style: AppTextStyles.button()),
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
                    'No, exit the app',
                    style: AppTextStyles.button(color: AppColors.textSecondary),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

              const SizedBox(height: AppSizes.xxl),

              Text(
                'By continuing, you agree to the Terms & Conditions\nand Privacy Policy of VirtualHeart.',
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
    ref.read(appSettingsProvider.notifier).save(settings.copyWith(isAgeVerified: true));
    context.go(AppRoutes.onboarding);
  }

  void _decline(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cannot Continue', style: AppTextStyles.headingSmall()),
        content: Text(
          'This app is for adults (18+) only. '
          'You cannot use VirtualHeart.',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: Text('Close App', style: AppTextStyles.button(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

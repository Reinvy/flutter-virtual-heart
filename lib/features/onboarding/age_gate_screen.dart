// Fitur Onboarding (FR-01) — age gate 13+.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../settings/settings_controller.dart';

class AgeGateScreen extends ConsumerWidget {
  const AgeGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: AppColors.primary)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOut),

              const SizedBox(height: AppSizes.spaceLg),

              Text(
                strings.ageGateTitle,
                style: AppTextStyles.headingLarge(),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

              const SizedBox(height: AppSizes.spaceMd),

              Text(
                strings.ageGateBody,
                style: AppTextStyles.bodyMedium(color: subtleColor),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

              const SizedBox(height: AppSizes.spaceXxl),

              PrimaryButton(
                label: strings.ageGateConfirm,
                onPressed: () => _confirm(context, ref),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

              const SizedBox(height: AppSizes.spaceMd),

              SecondaryButton(
                label: strings.ageGateDecline,
                onPressed: () => _decline(context),
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

              const SizedBox(height: AppSizes.spaceXxl),

              Text(
                strings.ageGateTerms,
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
    final strings = context.read(appStringsProvider);
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.ageGateCannotTitle, style: AppTextStyles.headingSmall()),
        content: Text(
          strings.ageGateCannotBody,
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: Text(strings.ageGateClose, style: AppTextStyles.button(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

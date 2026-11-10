// Fitur Onboarding (FR-01) — age gate 13+.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/bloom_mark.dart';
import '../../core/design/components/confirm_dialog.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class AgeGateScreen extends ConsumerWidget {
  const AgeGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: AppContent(
        maxWidth: 560,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceLg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSizes.spaceXxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const BloomMark(size: 28, glow: false),
                      const SizedBox(width: 10),
                      Text(
                        strings.appName,
                        style: AppTextStyles.headingSmall(
                          color: AppColors.primaryDeepFor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceMd),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spaceLg),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                      boxShadow: AppShadows.card(context),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                scheme.primaryContainer,
                                scheme.secondaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 36,
                            color: AppColors.primaryDeepFor(context),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        Text(
                          strings.ageGateTitle,
                          style: AppTextStyles.displaySmall(
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.ageGateBody,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondaryFor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.spaceSm),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.privacy),
                          child: Text(
                            strings.ageGatePrivacyLink,
                            style: AppTextStyles.titleSmall(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXs),
                        PrimaryButton(
                          label: strings.ageGateConfirm,
                          onPressed: () => _confirm(context, ref),
                        ),
                        const SizedBox(height: 10),
                        SecondaryButton(
                          label: strings.ageGateDecline,
                          onPressed: () => _decline(context, ref),
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: scheme.outlineVariant,
                        ),
                        const SizedBox(height: AppSizes.spaceSm),
                        Text(
                          strings.ageGateTerms,
                          style: AppTextStyles.caption(
                            color: AppColors.textSecondaryFor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final settings = ref.read(appSettingsProvider);
    ref
        .read(appSettingsProvider.notifier)
        .save(settings.copyWith(isAgeVerified: true));
    context.go(AppRoutes.onboarding);
  }

  void _decline(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    HapticFeedback.mediumImpact();
    showConfirmDialog(
      context,
      title: strings.ageGateCannotTitle,
      body: strings.ageGateCannotBody,
      confirmLabel: strings.ageGateClose,
      cancelLabel: strings.commonCancel,
      destructive: false,
    ).then((confirmed) {
      if (confirmed && context.mounted) SystemNavigator.pop();
    });
  }
}

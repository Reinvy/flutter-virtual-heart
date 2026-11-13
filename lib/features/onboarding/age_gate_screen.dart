// Fitur Onboarding (FR-01) — age gate 13+.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_icon_badge.dart';
import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/confirm_dialog.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/resonance_mark.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class AgeGateScreen extends ConsumerStatefulWidget {
  const AgeGateScreen({super.key});

  @override
  ConsumerState<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends ConsumerState<AgeGateScreen> {
  bool _confirming = false;
  bool _declining = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: AppContent(
        maxWidth: 560,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceLg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - AppSizes.spaceXxl).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const ResonanceMark(size: 24),
                      const SizedBox(width: AppSizes.spaceXs),
                      Expanded(
                        child: Text(
                          strings.appName,
                          style: AppTextStyles.headingSmall(
                            context,
                            color: AppColors.primaryDeepFor(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusBadge,
                          ),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          '13+',
                          style: AppTextStyles.badge(color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceMd),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spaceLg),
                    decoration: AppBorders.cardDecoration(context),
                    child: Column(
                      children: [
                        AppIconBadge(
                          icon: Icons.shield_outlined,
                          size: 52,
                          color: AppColors.primaryDeepFor(context),
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        Text(
                          strings.ageGateTitle,
                          style: AppTextStyles.displaySmall(
                            context,
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.spaceXs),
                        Text(
                          strings.ageGateBody,
                          style: AppTextStyles.bodyLarge(
                            color: AppColors.textSecondaryFor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        Material(
                          color: scheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            side: BorderSide(color: scheme.outlineVariant),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.privacy),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppSizes.touchTarget,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.spaceMd,
                                  vertical: AppSizes.spaceSm,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.privacy_tip_outlined,
                                      size: 18,
                                      color: AppColors.primaryDeepFor(context),
                                    ),
                                    const SizedBox(width: AppSizes.spaceSm),
                                    Expanded(
                                      child: Text(
                                        strings.ageGatePrivacyLink,
                                        style: AppTextStyles.titleSmall(
                                          color: AppColors.primaryDeepFor(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceLg),
                        PrimaryButton(
                          label: strings.ageGateConfirm,
                          onPressed: _confirming ? null : _confirm,
                        ),
                        const SizedBox(height: 10),
                        SecondaryButton(
                          label: strings.ageGateDecline,
                          onPressed: _declining ? null : _decline,
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

  void _confirm() {
    if (_confirming) return;
    _confirming = true;
    HapticFeedback.lightImpact();
    final settings = ref.read(appSettingsProvider);
    ref
        .read(appSettingsProvider.notifier)
        .save(settings.copyWith(isAgeVerified: true));
    if (mounted) context.go(AppRoutes.onboarding);
  }

  Future<void> _decline() async {
    if (_declining) return;
    _declining = true;
    final strings = ref.read(appStringsProvider);
    HapticFeedback.mediumImpact();
    try {
      final confirmed = await showConfirmDialog(
        context,
        title: strings.ageGateCannotTitle,
        body: strings.ageGateCannotBody,
        confirmLabel: strings.ageGateClose,
        cancelLabel: strings.commonCancel,
        destructive: false,
      );
      if (confirmed && mounted) SystemNavigator.pop();
    } finally {
      _declining = false;
    }
  }
}

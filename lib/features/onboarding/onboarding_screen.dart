// Fitur Onboarding (FR-02) — 3 halaman pengenalan.
//
// BloomMark berikon per halaman, indikator bar bergradien, skip di kanan atas.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/bloom_mark.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: AppDurations.durationSlow,
        curve: AppDurations.curveEmotive,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    final settings = ref.read(appSettingsProvider);
    ref
        .read(appSettingsProvider.notifier)
        .save(settings.copyWith(isOnboardingDone: true));
    context.go(AppRoutes.personaSetup);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isLast = _currentPage == 2;
    final scheme = Theme.of(context).colorScheme;

    final pages = [
      (
        icon: Icons.favorite_rounded,
        color: AppColors.accentFor(context),
        title: strings.onboardingPage1Title,
        body: strings.onboardingPage1Body,
      ),
      (
        icon: Icons.psychology_outlined,
        color: AppColors.secondaryFor(context),
        title: strings.onboardingPage2Title,
        body: strings.onboardingPage2Body,
      ),
      (
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primaryDeepFor(context),
        title: strings.onboardingPage3Title,
        body: strings.onboardingPage3Body,
      ),
    ];

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spaceLg,
              AppSizes.spaceSm,
              AppSizes.spaceSm,
              0,
            ),
            child: Row(
              children: [
                const BloomMark(size: 26, glow: false),
                const SizedBox(width: AppSizes.spaceXs),
                Text(
                  strings.appName,
                  style: AppTextStyles.headingSmall(
                    color: AppColors.primaryDeepFor(context),
                  ),
                ),
                const Spacer(),
                if (isLast)
                  const SizedBox(width: 72)
                else
                  GhostButton(
                    label: strings.onboardingSkip,
                    onPressed: _finish,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemCount: pages.length,
              itemBuilder: (_, index) => _PageContent(
                icon: pages[index].icon,
                color: pages[index].color,
                title: pages[index].title,
                body: pages[index].body,
                isActive: index == _currentPage,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (i) => AnimatedContainer(
                duration: AppDurations.durationNormal,
                curve: AppDurations.curveStandard,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 28 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: i == _currentPage ? null : scheme.outlineVariant,
                  gradient: i == _currentPage
                      ? AppGradients.selectedRing(context)
                      : null,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
            child: PrimaryButton(
              label: isLast
                  ? strings.onboardingGetStarted
                  : strings.onboardingNext,
              onPressed: _next,
            ),
          ),
          const SizedBox(height: AppSizes.spaceXl),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.isActive,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motionOk = !MediaQuery.disableAnimationsOf(context);

    final content = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceXl,
          vertical: AppSizes.spaceLg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.12),
                          color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  BloomMark(size: 148, icon: icon, animate: motionOk && isActive),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: AppTextStyles.displaySmall(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spaceSm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                body,
                style: AppTextStyles.bodyLarge(
                  color: AppColors.textSecondaryFor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ],
          ),
        ),
      ),
    );

    if (!motionOk) return content;
    return AnimatedOpacity(
      opacity: isActive ? 1 : 0.55,
      duration: AppDurations.durationSlow,
      curve: AppDurations.curveStandard,
      child: AnimatedSlide(
        offset: isActive ? Offset.zero : const Offset(0, 0.02),
        duration: AppDurations.durationSlow,
        curve: AppDurations.curveStandard,
        child: content,
      ),
    );
  }
}

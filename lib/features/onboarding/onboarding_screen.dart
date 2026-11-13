// Fitur Onboarding (FR-02) — 3 halaman pengenalan.
//
// ResonanceMark berikon di dalam bingkai hairline, indikator bar rata, skip di kanan atas.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/resonance_mark.dart';
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
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  void _next() {
    if (_finishing) return;
    HapticFeedback.lightImpact();
    final current = _controller.hasClients
        ? (_controller.page?.round() ?? _currentPage)
        : _currentPage;
    if (current < 2) {
      _controller.animateToPage(
        current + 1,
        duration: AppDurations.durationSlow,
        curve: AppDurations.curveEmotive,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    if (_finishing) return;
    _finishing = true;
    final settings = ref.read(appSettingsProvider);
    ref
        .read(appSettingsProvider.notifier)
        .save(settings.copyWith(isOnboardingDone: true));
    if (mounted) context.go(AppRoutes.personaSetup);
  }
  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isLast = _currentPage == 2;
    final scheme = Theme.of(context).colorScheme;

    final pages = [
      (
        icon: Icons.favorite_outline_rounded,
        title: strings.onboardingPage1Title,
        body: strings.onboardingPage1Body,
      ),
      (
        icon: Icons.psychology_outlined,
        title: strings.onboardingPage2Title,
        body: strings.onboardingPage2Body,
      ),
      (
        icon: Icons.auto_awesome_outlined,
        title: strings.onboardingPage3Title,
        body: strings.onboardingPage3Body,
      ),
    ];

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pageGutter,
              AppSizes.spaceSm,
              AppSizes.spaceSm,
              0,
            ),
            child: Row(
              children: [
                const ResonanceMark(size: 24),
                const SizedBox(width: AppSizes.spaceXs),
                Flexible(
                  child: Text(
                    strings.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall(
                      context,
                      color: AppColors.primaryDeepFor(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Text(
                  strings.onboardingStep(_currentPage + 1, pages.length),
                  style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                ),
                const Spacer(),
                if (!isLast)
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
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 32 : 12,
                height: 3,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? scheme.primary
                      : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: PrimaryButton(
                label: isLast
                    ? strings.onboardingGetStarted
                    : strings.onboardingNext,
                onPressed: _next,
              ),
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
    required this.title,
    required this.body,
    required this.isActive,
  });

  final IconData icon;
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
          horizontal: AppSizes.pageGutter,
          vertical: AppSizes.spaceLg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: AppBorders.cardDecoration(
                  context,
                  radius: AppSizes.radiusCard,
                ),
                alignment: Alignment.center,
                child: ResonanceMark(
                  size: 132,
                  icon: icon,
                  animate: motionOk && isActive,
                ),
              ),
              const SizedBox(height: AppSizes.spaceXl),
              Text(
                title,
                style: AppTextStyles.displaySmall(
                  context,
                  color: scheme.onSurface,
                ),
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

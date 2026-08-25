// Fitur Onboarding (FR-02) — 3 halaman pengenalan.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../settings/settings_controller.dart';

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
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    final settings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).save(settings.copyWith(isOnboardingDone: true));
    context.go(AppRoutes.personaSetup);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isLast = _currentPage == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final pages = [
      (icon: Icons.favorite, color: AppColors.heartRed, title: strings.onboardingPage1Title, body: strings.onboardingPage1Body),
      (icon: Icons.psychology_outlined, color: AppColors.secondary, title: strings.onboardingPage2Title, body: strings.onboardingPage2Body),
      (icon: Icons.auto_awesome, color: AppColors.primary, title: strings.onboardingPage3Title, body: strings.onboardingPage3Body),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: TextButton(
                  onPressed: isLast ? null : _finish,
                  child: Text(
                    strings.onboardingSkip,
                    style: AppTextStyles.button(color: subtleColor),
                  ),
                ),
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
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXxs),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppColors.primary : subtleColor.withAlpha(80),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spaceLg),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
              child: PrimaryButton(
                label: isLast ? strings.onboardingGetStarted : strings.onboardingNext,
                onPressed: _next,
              ),
            ),

            const SizedBox(height: AppSizes.spaceXl),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(25),
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(60), blurRadius: 40, spreadRadius: 8),
                  ],
                ),
                child: Icon(icon, size: 56, color: color),
              )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 450.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 450.ms),

          const SizedBox(height: AppSizes.spaceXl),

          Text(
                title,
                style: AppTextStyles.headingLarge(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.15, end: 0, duration: 400.ms, delay: 100.ms),

          const SizedBox(height: AppSizes.spaceMd),

          Text(
                body,
                style: AppTextStyles.bodyMedium(color: subtleColor),
                textAlign: TextAlign.center,
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.15, end: 0, duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}

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

// ── Onboarding page data ──────────────────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    icon: Icons.favorite,
    iconColor: AppColors.heartRed,
    title: 'Teman Hatimu',
    body:
        'VirtualHeart hadir sebagai teman setia yang selalu siap mendengar, '
        'mendukung, dan menemanimu kapan saja.',
  ),
  _OnboardingPage(
    icon: Icons.psychology_outlined,
    iconColor: AppColors.secondary,
    title: 'Cerdas & Pribadi',
    body:
        'AI kami berjalan sepenuhnya di perangkatmu — privasi terjaga, '
        'tidak ada data yang dikirim ke server mana pun.',
  ),
  _OnboardingPage(
    icon: Icons.auto_awesome,
    iconColor: AppColors.primary,
    title: 'Sesuaikan Segalanya',
    body:
        'Pilih nama, kepribadian, dan tampilan pasangan virtualmu. '
        'Rasakan pengalaman yang benar-benar personal.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────

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
    if (_currentPage < _pages.length - 1) {
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
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top-right, hidden on last page)
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: TextButton(
                  onPressed: isLast ? null : _finish,
                  child: Text(
                    'Lewati',
                    style: AppTextStyles.button(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, index) =>
                    _PageContent(page: _pages[index], isActive: index == _currentPage),
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.textSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // CTA button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      isLast ? 'Mulai Sekarang' : 'Lanjut',
                      key: ValueKey(isLast),
                      style: AppTextStyles.button(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

// ── Individual page content ───────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  final bool isActive;

  const _PageContent({required this.page, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with radial glow
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page.iconColor.withAlpha(25),
                  boxShadow: [
                    BoxShadow(color: page.iconColor.withAlpha(60), blurRadius: 40, spreadRadius: 8),
                  ],
                ),
                child: Icon(page.icon, size: 56, color: page.iconColor),
              )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 450.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 450.ms),

          const SizedBox(height: AppSizes.xl),

          Text(page.title, style: AppTextStyles.headingLarge(), textAlign: TextAlign.center)
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.15, end: 0, duration: 400.ms, delay: 100.ms),

          const SizedBox(height: AppSizes.md),

          Text(
                page.body,
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/model_ready_provider.dart';
import '../../providers/router_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final settings = ref.read(appSettingsProvider);
    final isModelReady = ref.read(modelReadyProvider);

    if (!settings.isAgeVerified) {
      context.go(AppRoutes.ageGate);
    } else if (!settings.isOnboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (!settings.isPersonaSetup) {
      context.go(AppRoutes.personaSetup);
    } else if (!isModelReady) {
      context.go(AppRoutes.modelDownload);
    } else {
      context.go(AppRoutes.chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Floating heart particles — decorative background animation
          for (int i = 0; i < 7; i++) _FloatingHeart(index: i),

          // Main centred content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated heart icon
                const Icon(Icons.favorite, size: 72, color: AppColors.heartRed)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .shimmer(duration: 1200.ms, color: AppColors.primary.withAlpha(100)),

                const SizedBox(height: AppSizes.lg),

                // App name
                Text('VirtualHeart', style: AppTextStyles.appName())
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 300.ms),

                const SizedBox(height: AppSizes.sm),

                Text(
                  'Your heart\'s companion, always here.',
                  style: AppTextStyles.moodIndicator(),
                ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating heart particles ───────────────────────────────────────────────────

/// Decorative heart icon that floats upward with a staggered fade-in /
/// move-up / fade-out animation. Uses predetermined positions so the widget
/// stays pure (no [Random] calls during build).
class _FloatingHeart extends StatelessWidget {
  const _FloatingHeart({required this.index});

  final int index;

  // [left_fraction, bottom_fraction, icon_size, delay_ms]
  static const List<List<double>> _configs = [
    [0.08, 0.08, 12, 0],
    [0.22, 0.14, 9, 400],
    [0.68, 0.10, 16, 200],
    [0.82, 0.20, 10, 600],
    [0.42, 0.05, 14, 100],
    [0.55, 0.22, 8, 700],
    [0.12, 0.30, 18, 300],
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cfg = _configs[index];
    final color = index.isEven ? AppColors.primary : AppColors.heartRed;

    return Positioned(
      left: size.width * cfg[0],
      bottom: size.height * cfg[1],
      child: Icon(Icons.favorite_rounded, size: cfg[2], color: color.withAlpha(110))
          .animate(delay: Duration(milliseconds: cfg[3].toInt()))
          .fadeIn(duration: 350.ms)
          .moveY(begin: 0, end: -130, duration: 2300.ms, curve: Curves.easeOut)
          .fadeOut(delay: 1500.ms, duration: 800.ms),
    );
  }
}

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
      body: Center(
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
              'Teman hatimu, selalu di sini.',
              style: AppTextStyles.moodIndicator(),
            ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

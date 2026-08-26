// Fitur Onboarding — layar splash (alur awal).
//
// "Sakura Fall": gradien blush lembut, logo hati berdenyut dalam lingkaran
// rose, dan kelopak sakura melayang (CustomPainter, tanpa aset).
// Menghormati MediaQuery.disableAnimations.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/sakura_background.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/router/app_router.dart';
import '../model/model_ready_provider.dart';
import '../settings/settings_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(seconds: 2));

    final settings = ref.read(appSettingsProvider);
    final isModelReady = ref.read(modelReadyProvider);
    final String route;

    if (!settings.isAgeVerified) {
      route = AppRoutes.ageGate;
    } else if (!settings.isOnboardingDone) {
      route = AppRoutes.onboarding;
    } else if (!settings.isPersonaSetup) {
      route = AppRoutes.personaSetup;
    } else if (!isModelReady) {
      route = AppRoutes.modelDownload;
    } else {
      route = AppRoutes.chat;
    }

    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motionOk = !MediaQuery.disableAnimationsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1A0F1E), Color(0xFF2A1B26)]
                : [AppColors.primarySoft, Colors.white, AppColors.secondarySoft],
            stops: isDark ? null : const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: SakuraBackground(petals: 10, opacity: 1)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [AppColors.primaryDark, AppColors.primarySoftDark]
                            : [AppColors.primary, AppColors.primarySoft],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.favorite, size: 56, color: Colors.white),
                  ).animate(
                    onPlay: motionOk ? (c) => c.repeat(reverse: true) : null,
                  ).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  Text(
                    'VirtualHeart',
                    style: AppTextStyles.appName(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDeep,
                    ).copyWith(fontSize: 28),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                  const SizedBox(height: AppSizes.spaceXs),
                  Text(
                    'a sakura romance',
                    style: AppTextStyles.moodIndicator(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 350.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

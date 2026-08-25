// Fitur Onboarding — layar splash (alur awal).
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, size: 72, color: Colors.white)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: AppSizes.spaceMd),
                  Text(
                    'VirtualHeart',
                    style: AppTextStyles.appName(color: Colors.white).copyWith(fontSize: 28),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                ],
              ),
            ),
            for (int i = 0; i < 7; i++)
              _FloatingHeart(
                left: (i * 13.0) % 100 / 100 * MediaQuery.of(context).size.width,
                delay: Duration(milliseconds: i * 350),
                duration: Duration(seconds: 4 + (i % 3)),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingHeart extends StatelessWidget {
  const _FloatingHeart({
    required this.left,
    required this.delay,
    required this.duration,
  });

  final double left;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      bottom: -40,
      child: Icon(
        Icons.favorite,
        size: 18 + (left / 10),
        color: Colors.white.withAlpha(120),
      ).animate(
        delay: delay,
        onPlay: (c) => c.repeat(),
      ).moveY(begin: 0, end: -MediaQuery.of(context).size.height - 60, duration: duration),
    );
  }
}

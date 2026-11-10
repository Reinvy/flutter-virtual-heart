// Fitur Onboarding — layar splash (alur awal).
//
// BloomMark bernapas di atas latar senja; tiga titik menandakan proses boot.
// Menghormati MediaQuery.disableAnimations.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/bloom_mark.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../services/ai/model_service.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

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
    final modelReadyFuture = _loadModelReady();
    await Future<void>.delayed(const Duration(seconds: 2));
    final isModelReady = await modelReadyFuture;

    final settings = ref.read(appSettingsProvider);
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

  /// Menunggu model selesai dimuat (dibatasi 8 detik agar splash tidak macet).
  Future<bool> _loadModelReady() async {
    try {
      return await ref
          .read(modelServiceProvider.future)
          .then((status) => status.ready)
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return AppScaffold(
      safeArea: false,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BloomMark(size: 132, animate: true),
              const SizedBox(height: AppSizes.spaceXl),
              Text(
                strings.appName,
                style: AppTextStyles.displayHero(
                  color: AppColors.primaryDeepFor(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.appTagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(
                  color: AppColors.textSecondaryFor(context),
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 40),
              const _BootDots(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootDots extends StatefulWidget {
  const _BootDots();

  @override
  State<_BootDots> createState() => _BootDotsState();
}

class _BootDotsState extends State<_BootDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _motionOk = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ok = !MediaQuery.disableAnimationsOf(context);
    if (ok == _motionOk) return;
    _motionOk = ok;
    if (ok) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i / 3) % 1;
            final alpha = _motionOk
                ? 0.35 + 0.65 * (1 - (2 * phase - 1).abs())
                : 0.5;
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: alpha),
              ),
            );
          }),
        );
      },
    );
  }
}

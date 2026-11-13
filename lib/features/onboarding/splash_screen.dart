// Fitur Onboarding — layar splash (alur awal).
//
// ResonanceMark di atas kanvas editorial; hairline boot bar menandakan boot.
// Menghormati MediaQuery.disableAnimations.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/resonance_mark.dart';
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
      route = AppRoutes.hub;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ResonanceMark(size: 112, animate: true),
                const SizedBox(height: AppSizes.spaceXl),
                Text(
                  strings.appName,
                  style: AppTextStyles.displayHero(
                    context,
                    color: AppColors.primaryDeepFor(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.appTagline.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionLabel(
                    color: AppColors.textSecondaryFor(context),
                  ).copyWith(letterSpacing: 2.0),
                ),
                const SizedBox(height: 40),
                const _BootHairline(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootHairline extends StatefulWidget {
  const _BootHairline();

  @override
  State<_BootHairline> createState() => _BootHairlineState();
}

class _BootHairlineState extends State<_BootHairline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 120,
      height: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Stack(
          children: [
            ColoredBox(color: scheme.outlineVariant, child: const SizedBox.expand()),
            if (_motionOk)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final x = (_controller.value * 2 - 1) * 0.85;
                  return Align(
                    alignment: Alignment(x, 0),
                    child: Container(
                      width: 44,
                      height: 2,
                      color: scheme.primary,
                    ),
                  );
                },
              )
            else
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 2,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

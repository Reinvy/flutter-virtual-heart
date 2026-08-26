// Router aplikasi (docs/DESIGN.md §7) — GoRouter + route guards
//
// Dipindah dari `providers/router_provider.dart` ke `core/router/`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_screen.dart';
import '../../features/memory/memory_screen.dart';
import '../../features/model/model_download_screen.dart';
import '../../features/model/model_ready_provider.dart';
import '../../features/onboarding/age_gate_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/persona/persona_setup_screen.dart';
import '../../features/settings/settings_controller.dart';
import '../../features/settings/settings_screen.dart';
import '../design/tokens/app_durations.dart';

/// Named route paths.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const ageGate = '/age-gate';
  static const onboarding = '/onboarding';
  static const personaSetup = '/persona-setup';
  static const modelDownload = '/model-download';
  static const chat = '/chat';
  static const memory = '/memory';
  static const settings = '/settings';
}

/// Menjembatani perubahan state Riverpod ke `GoRouter.refreshListenable`
/// agar redirect guard dievaluasi ulang saat [AppSettings] atau modelReady
/// berubah.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(appSettingsProvider, (_, _) => notifyListeners());
    ref.listen(modelReadyProvider, (_, _) => notifyListeners());
  }
}

/// Halaman transisi: fade + slide halus (token motion).
CustomTransitionPage<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.durationNormal,
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppDurations.curveStandard),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppDurations.curveStandard)),
          child: child,
        ),
      );
    },
  );
}

/// Menyediakan instance [GoRouter] aplikasi.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final path = state.uri.path;

      // Splash + model-download mengelola navigasinya sendiri.
      if (path == AppRoutes.splash || path == AppRoutes.modelDownload) {
        return null;
      }

      final settings = ref.read(appSettingsProvider);
      final isModelReady = ref.read(modelReadyProvider);

      // Step 1 — age gate (FR-01)
      if (!settings.isAgeVerified) {
        return path == AppRoutes.ageGate ? null : AppRoutes.ageGate;
      }

      // Step 2 — onboarding
      if (!settings.isOnboardingDone) {
        return path == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // Step 3 — persona setup
      if (!settings.isPersonaSetup) {
        return path == AppRoutes.personaSetup ? null : AppRoutes.personaSetup;
      }

      // Step 4 — model harus siap
      if (!isModelReady) {
        return path == AppRoutes.modelDownload ? null : AppRoutes.modelDownload;
      }

      // Semua kondisi terpenuhi — redirect menjauh dari layar setup.
      const setupRoutes = {AppRoutes.ageGate, AppRoutes.onboarding, AppRoutes.personaSetup};
      if (setupRoutes.contains(path)) return AppRoutes.chat;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, pageBuilder: (context, state) => _buildPage(state, const SplashScreen())),
      GoRoute(path: AppRoutes.ageGate, pageBuilder: (context, state) => _buildPage(state, const AgeGateScreen())),
      GoRoute(path: AppRoutes.onboarding, pageBuilder: (context, state) => _buildPage(state, const OnboardingScreen())),
      GoRoute(path: AppRoutes.personaSetup, pageBuilder: (context, state) => _buildPage(state, const PersonaSetupScreen())),
      GoRoute(path: AppRoutes.modelDownload, pageBuilder: (context, state) => _buildPage(state, const ModelDownloadScreen())),
      GoRoute(path: AppRoutes.chat, pageBuilder: (context, state) => _buildPage(state, const ChatScreen())),
      GoRoute(path: AppRoutes.memory, pageBuilder: (context, state) => _buildPage(state, const MemoryScreen())),
      GoRoute(path: AppRoutes.settings, pageBuilder: (context, state) => _buildPage(state, const SettingsScreen())),
    ],
  );
});

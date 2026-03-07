import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/age_gate/age_gate_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/memory/memory_screen.dart';
import '../screens/model_download/model_download_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/persona_setup/persona_setup_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'app_settings_provider.dart';
import 'model_ready_provider.dart';

/// Named route paths used throughout the app.
abstract class AppRoutes {
  static const splash = '/splash';
  static const ageGate = '/age-gate';
  static const onboarding = '/onboarding';
  static const personaSetup = '/persona-setup';
  static const modelDownload = '/model-download';
  static const chat = '/chat';
  static const memory = '/memory';
  static const settings = '/settings';
}

/// A [ChangeNotifier] that bridges Riverpod state changes into go_router's
/// [GoRouter.refreshListenable]. Notifies the router whenever [AppSettings]
/// or [modelReadyProvider] change so the redirect guard is re-evaluated.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(appSettingsProvider, (_, __) => notifyListeners());
    ref.listen(modelReadyProvider, (_, __) => notifyListeners());
  }
}

/// Provides the app-wide [GoRouter] instance.
///
/// The router is recreated whenever [appSettingsProvider] or
/// [modelReadyProvider] changes, re-running the redirect guard.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final path = state.uri.path;

      // Splash + model-download manage their own navigation flow.
      if (path == AppRoutes.splash || path == AppRoutes.modelDownload) {
        return null;
      }

      final settings = ref.read(appSettingsProvider);
      final isModelReady = ref.read(modelReadyProvider);

      // Step 1 — age verification (FR-01)
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

      // Step 4 — model must be loaded (Phase 1.4 sets modelReadyProvider)
      if (!isModelReady) {
        return path == AppRoutes.modelDownload ? null : AppRoutes.modelDownload;
      }

      // All conditions met — redirect away from setup screens if user navigates
      // back to them (e.g., via deep link or back button edge case).
      const setupRoutes = {AppRoutes.ageGate, AppRoutes.onboarding, AppRoutes.personaSetup};
      if (setupRoutes.contains(path)) return AppRoutes.chat;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.ageGate, builder: (context, state) => const AgeGateScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: AppRoutes.personaSetup,
        builder: (context, state) => const PersonaSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.modelDownload,
        builder: (context, state) => const ModelDownloadScreen(),
      ),
      GoRoute(path: AppRoutes.chat, builder: (context, state) => const ChatScreen()),
      GoRoute(path: AppRoutes.memory, builder: (context, state) => const MemoryScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
    ],
  );
});

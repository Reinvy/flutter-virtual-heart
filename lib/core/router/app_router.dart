// Router aplikasi (docs/DESIGN.md §7) — GoRouter + StatefulShellRoute 4-tab + route guards
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_screen.dart';
import '../../features/hub/companion_hub_screen.dart';
import '../../features/memory/memory_screen.dart';
import '../../features/model/model_download_screen.dart';
import '../../features/onboarding/age_gate_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/persona/persona_setup_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../models/app_settings.dart';
import '../design/components/app_scaffold.dart';
import '../design/components/empty_state.dart';
import '../design/components/main_shell_scaffold.dart';
import '../design/components/secondary_button.dart';
import '../design/tokens/app_durations.dart';
import '../l10n/app_strings.dart';
import 'package:virtual_heart/services/ai/model_ready_provider.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

/// Named route paths.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const ageGate = '/age-gate';
  static const privacy = '/privacy';
  static const onboarding = '/onboarding';
  static const personaSetup = '/persona-setup';
  static const modelDownload = '/model-download';
  static const hub = '/hub';
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
    reverseTransitionDuration: AppDurations.durationNormal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final height = MediaQuery.sizeOf(context).height;
      final dy = height > 0 ? 8 / height : 0.0;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppDurations.curveStandard,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, dy),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Aturan guard route — fungsi murni supaya bisa dites tanpa GoRouter.
///
/// Urutan gate: age verification → onboarding → persona setup → model siap.
/// `/splash` selalu lolos (layar ini yang memutuskan langkah berikutnya).
/// `/model-download` **tidak** punya bypass: gate umur/onboarding/persona tetap
/// berlaku untuk rute tersebut.
String? resolveRedirect({
  required String path,
  required AppSettings settings,
  required bool isModelReady,
  Map<String, String> queryParameters = const {},
}) {
  if (path == AppRoutes.splash) return null;
  if (path == AppRoutes.privacy) return null;

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
  const setupRoutes = {
    AppRoutes.ageGate,
    AppRoutes.onboarding,
    AppRoutes.personaSetup,
  };
  if (setupRoutes.contains(path)) return AppRoutes.hub;
  if (path == AppRoutes.modelDownload && queryParameters['auto'] == '1') {
    return AppRoutes.hub;
  }

  return null;
}

/// Menyediakan instance [GoRouter] aplikasi.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => resolveRedirect(
      path: state.uri.path,
      settings: ref.read(appSettingsProvider),
      isModelReady: ref.read(modelReadyProvider),
      queryParameters: state.uri.queryParameters,
    ),
    errorBuilder: (context, state) => const _RouterErrorScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.ageGate,
        pageBuilder: (context, state) =>
            _buildPage(state, const AgeGateScreen()),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        pageBuilder: (context, state) =>
            _buildPage(state, const PrivacyScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _buildPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.personaSetup,
        pageBuilder: (context, state) =>
            _buildPage(state, const PersonaSetupScreen()),
      ),
      GoRoute(
        path: AppRoutes.modelDownload,
        pageBuilder: (context, state) =>
            _buildPage(state, const ModelDownloadScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hub,
                pageBuilder: (context, state) =>
                    _buildPage(state, const CompanionHubScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                pageBuilder: (context, state) =>
                    _buildPage(state, const ChatScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.memory,
                pageBuilder: (context, state) =>
                    _buildPage(state, const MemoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: (context, state) =>
                    _buildPage(state, const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Layar fallback bila rute tidak dikenal / gagal dibangun.
class _RouterErrorScreen extends ConsumerWidget {
  const _RouterErrorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return AppScaffold(
      body: EmptyState(
        mark: true,
        icon: Icons.error_outline_rounded,
        title: strings.routeNotFoundTitle,
        body: strings.routeNotFoundBody,
        action: GhostButton(
          label: strings.routeGoHome,
          onPressed: () => context.go(AppRoutes.splash),
        ),
      ),
    );
  }
}

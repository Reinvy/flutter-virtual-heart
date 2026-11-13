// Widget test — MainShellScaffold 4-tab navigation & 320dp overflow check.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:virtual_heart/core/design/active_shell_tab_provider.dart';
import 'package:virtual_heart/core/design/app_theme.dart';
import 'package:virtual_heart/core/design/components/main_shell_scaffold.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/core/router/app_router.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class _TestSettingsNotifier extends AppSettingsNotifier {
  _TestSettingsNotifier(this.value);
  final AppSettings value;

  @override
  AppSettings build() => value;
}

void main() {
  testWidgets(
    '4 tab tampil di 320x800 tanpa overflow dan memperbarui activeShellTabProvider',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: AppRoutes.hub,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => MainShellScaffold(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.hub,
                    builder: (_, _) => const Scaffold(body: Text('BRANCH_HUB')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.chat,
                    builder: (_, _) =>
                        const Scaffold(body: Text('BRANCH_CHAT')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.memory,
                    builder: (_, _) =>
                        const Scaffold(body: Text('BRANCH_MEMORY')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.settings,
                    builder: (_, _) =>
                        const Scaffold(body: Text('BRANCH_SETTINGS')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              () => _TestSettingsNotifier(AppSettings()),
            ),
            appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(
                theme: AppTheme.light,
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Obrolan'), findsOneWidget);
      expect(find.text('Memori'), findsOneWidget);
      expect(find.text('Setelan'), findsOneWidget);
      expect(container.read(activeShellTabProvider), 0);

      await tester.tap(find.byKey(const ValueKey('shell-tab-2')));
      await tester.pumpAndSettle();
      expect(find.text('BRANCH_MEMORY'), findsOneWidget);
      expect(container.read(activeShellTabProvider), 2);

      await tester.tap(find.byKey(const ValueKey('shell-tab-3')));
      await tester.pumpAndSettle();
      expect(find.text('BRANCH_SETTINGS'), findsOneWidget);
      expect(container.read(activeShellTabProvider), 3);

      await tester.tap(find.byKey(const ValueKey('shell-tab-1')));
      await tester.pumpAndSettle();
      expect(find.text('BRANCH_CHAT'), findsOneWidget);
      expect(container.read(activeShellTabProvider), 1);
    },
  );

  testWidgets(
    'back di Hub butuh 2x untuk keluar, back di tab lain kembali ke Hub',
    (tester) async {
      var systemPopCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.pop') {
              systemPopCalls++;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final router = GoRouter(
        initialLocation: AppRoutes.hub,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => MainShellScaffold(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.hub,
                    builder: (_, _) => const Scaffold(body: Text('BRANCH_HUB')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.chat,
                    builder: (_, _) =>
                        const Scaffold(body: Text('BRANCH_CHAT')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.memory,
                    builder: (_, _) =>
                        const Scaffold(body: Text('BRANCH_MEMORY')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.settings,
                    builder: (_, _) =>
                        const Scaffold(body: Text('BRANCH_SETTINGS')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              () => _TestSettingsNotifier(AppSettings()),
            ),
            appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp.router(
                theme: AppTheme.light,
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab Settings, tekan back → kembali ke Hub tanpa keluar/prompt.
      await tester.tap(find.byKey(const ValueKey('shell-tab-3')));
      await tester.pumpAndSettle();
      expect(container.read(activeShellTabProvider), 3);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(container.read(activeShellTabProvider), 0);
      expect(find.text('BRANCH_HUB'), findsOneWidget);
      expect(systemPopCalls, 0);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsNothing);

      // Tekan back pertama di Hub → tidak keluar, munculkan prompt.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(systemPopCalls, 0);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsOneWidget);

      // Pindah tab ke Chat → reset prompt, lalu kembali ke Hub.
      await tester.tap(find.byKey(const ValueKey('shell-tab-1')));
      await tester.pumpAndSettle();
      expect(find.text('Tekan sekali lagi untuk keluar'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(container.read(activeShellTabProvider), 0);

      // Tekan back pertama lagi di Hub → masih muncul prompt, belum keluar.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(systemPopCalls, 0);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsOneWidget);

      // Tekan back kedua di Hub → keluar aplikasi.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(systemPopCalls, 1);
    },
  );
}

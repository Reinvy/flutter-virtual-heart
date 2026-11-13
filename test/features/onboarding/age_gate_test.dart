// Widget test — AgeGateScreen (FR-01): verifikasi 13+, konfirmasi, privasi.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/onboarding/age_gate_screen.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class FakeSettingsNotifier extends AppSettingsNotifier {
  FakeSettingsNotifier(this.initial);

  final AppSettings initial;
  AppSettings? saved;

  @override
  AppSettings build() => initial;

  @override
  void save(AppSettings updated) {
    saved = updated;
    state = updated;
  }
}

Widget wrap({
  FakeSettingsNotifier? notifier,
  AppSettings? settings,
  AppStrings? strings,
}) {
  final router = GoRouter(
    initialLocation: '/age-gate',
    routes: [
      GoRoute(path: '/age-gate', builder: (_, _) => const AgeGateScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const Scaffold(body: Text('ONBOARDING')),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, _) => const Scaffold(body: Text('PRIVACY')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(
        () => notifier ?? FakeSettingsNotifier(settings ?? AppSettings()),
      ),
      appStringsProvider.overrideWith(
        (ref) => strings ?? const IndonesianStrings(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Matikan animasi global → flutter_animate tidak membuat pending timer.
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('menampilkan verifikasi 13+ (Indonesia, default)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Usia'), findsOneWidget);
    expect(find.text('Ya, saya 13 tahun ke atas'), findsOneWidget);
    expect(find.text('Tidak, keluar dari aplikasi'), findsOneWidget);
  });

  testWidgets('konfirmasi menandai isAgeVerified dan lanjut ke onboarding', (
    tester,
  ) async {
    final notifier = FakeSettingsNotifier(AppSettings());
    await tester.pumpWidget(wrap(notifier: notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ya, saya 13 tahun ke atas'));
    await tester.pumpAndSettle();

    expect(notifier.saved?.isAgeVerified, isTrue);
    expect(find.text('ONBOARDING'), findsOneWidget);
  });

  testWidgets('tautan kebijakan privasi bisa dibuka sebelum menyetujui', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Baca Kebijakan Privasi'));
    await tester.pumpAndSettle();

    expect(find.text('PRIVACY'), findsOneWidget);
  });

  testWidgets('bahasa Inggris tampil saat language = english', (tester) async {
    await tester.pumpWidget(
      wrap(
        settings: AppSettings(language: AppLanguage.english),
        strings: const EnglishStrings(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Age Verification'), findsOneWidget);
    expect(find.text('Yes, I am 13 or older'), findsOneWidget);
  });

  testWidgets(
    'back sekali tidak menutup aplikasi di age gate; 2x baru keluar',
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

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Buka privasi lalu back → kembali ke age gate tanpa keluar/prompt.
      await tester.tap(find.text('Baca Kebijakan Privasi'));
      await tester.pumpAndSettle();
      expect(find.text('PRIVACY'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Verifikasi Usia'), findsOneWidget);
      expect(systemPopCalls, 0);

      // Back pertama di age gate → muncul prompt, belum keluar.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(systemPopCalls, 0);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsOneWidget);

      // Back kedua → keluar aplikasi.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(systemPopCalls, 1);
    },
  );
}

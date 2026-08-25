// Widget test — AgeGateScreen (FR-01): verifikasi 13+ & konfirmasi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/onboarding/age_gate_screen.dart';
import 'package:virtual_heart/features/settings/settings_controller.dart';
import 'package:virtual_heart/models/app_settings.dart';

class _TestSettingsNotifier extends AppSettingsNotifier {
  _TestSettingsNotifier(this.value);
  final AppSettings value;

  @override
  AppSettings build() => value;
}

Widget wrap({AppSettings? settings, AppStrings? strings}) {
  return ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(
        () => _TestSettingsNotifier(settings ?? AppSettings()),
      ),
      appStringsProvider.overrideWith((ref) => strings ?? const IndonesianStrings()),
    ],
    child: const MaterialApp(home: AgeGateScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Matikan animasi global → flutter_animate tidak membuat pending timer.
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('menampilkan verifikasi 13+ (Indonesia, default)', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Usia'), findsOneWidget);
    expect(find.text('Ya, saya 13 tahun ke atas'), findsOneWidget);
    expect(find.text('Tidak, keluar dari aplikasi'), findsOneWidget);
  });

  testWidgets('tombol confirm & decline tersedia', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Ya, saya 13 tahun ke atas'), findsOneWidget);
    expect(find.text('Tidak, keluar dari aplikasi'), findsOneWidget);
  });

  testWidgets('bahasa Inggris tampil saat language = english', (tester) async {
    await tester.pumpWidget(wrap(
      settings: AppSettings(language: AppLanguage.english),
      strings: const EnglishStrings(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Age Verification'), findsOneWidget);
    expect(find.text('Yes, I am 13 or older'), findsOneWidget);
  });
}

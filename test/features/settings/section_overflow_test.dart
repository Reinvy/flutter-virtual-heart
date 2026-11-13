// Widget test — layout sempit (320 dp) & seleksi preset tema (DESIGN §5).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/design/app_theme.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'package:virtual_heart/features/settings/widgets/appearance_section.dart';
import 'package:virtual_heart/features/settings/widgets/language_section.dart';
import 'package:virtual_heart/features/settings/widgets/model_section.dart';
import 'package:virtual_heart/models/app_settings.dart';

class _TestSettingsNotifier extends AppSettingsNotifier {
  _TestSettingsNotifier(this.value);
  final AppSettings value;

  @override
  AppSettings build() => value;

  @override
  void save(AppSettings updated) {
    state = updated;
  }
}

void main() {
  testWidgets('section Appearance/Language/Model muat di 320 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = AppSettings(
      theme: AppThemeSetting.system,
      language: AppLanguage.mixed,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(() => _TestSettingsNotifier(settings)),
          appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: [
                AppearanceSection(settings: settings),
                LanguageSection(settings: settings),
                ModelSection(settings: settings),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TAMPILAN'), findsOneWidget);
    expect(find.text('BAHASA AI'), findsOneWidget);
    expect(find.text('MODEL AI'), findsOneWidget);
  });

  testWidgets('memilih preset tema Romantic & mode gelap memperbarui AppSettings tanpa overflow di 320 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final initial = AppSettings();
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(() => _TestSettingsNotifier(initial)),
          appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final current = ref.watch(appSettingsProvider);
            return MaterialApp(
              theme: AppTheme.lightFor(current.themeStyle),
              darkTheme: AppTheme.darkFor(current.themeStyle),
              themeMode: current.theme == AppThemeSetting.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              home: Scaffold(
                body: ListView(
                  children: [AppearanceSection(settings: current)],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('theme-style-romantic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-option-dark')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final updated = container.read(appSettingsProvider);
    expect(updated.themeStyle, AppThemeStyle.romantic);
    expect(updated.theme, AppThemeSetting.dark);
  });
}

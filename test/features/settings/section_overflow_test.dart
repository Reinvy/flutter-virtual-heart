// Widget test — layout sempit (320 dp) untuk section Settings (DESIGN §5).
//
// Overflow dilaporkan sebagai FlutterError saat layout; `takeException()`
// memastikan tidak ada RenderFlex overflow pada lebar minimum.
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
}

void main() {
  testWidgets('section Appearance/Language/Model muat di 320 dp', (tester) async {
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
}

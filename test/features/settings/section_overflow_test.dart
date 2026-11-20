// Widget test — layout sempit (320 dp) & seleksi preset tema (DESIGN §5).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/design/app_theme.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/model/cloud_provider_editor_sheet.dart';
import 'package:virtual_heart/features/settings/widgets/appearance_section.dart';
import 'package:virtual_heart/features/settings/widgets/cloud_speech_sheet.dart';
import 'package:virtual_heart/features/settings/widgets/language_section.dart';
import 'package:virtual_heart/features/settings/widgets/model_section.dart';
import 'package:virtual_heart/features/settings/widgets/voice_section.dart';
import 'package:virtual_heart/models/ai_provider_profile.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/cloud_speech_config.dart';
import 'package:virtual_heart/services/ai/ai_provider_controller.dart';
import 'package:virtual_heart/services/ai/secret_store.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

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

class _TestProfilesNotifier extends AiProviderProfilesNotifier {
  _TestProfilesNotifier(this.initial);
  final List<AiProviderProfile> initial;

  @override
  List<AiProviderProfile> build() => initial;
}

class _TestSpeechConfigNotifier extends CloudSpeechConfigNotifier {
  _TestSpeechConfigNotifier(this.initial);
  final CloudSpeechConfig initial;

  @override
  CloudSpeechConfig build() => initial;

  @override
  void save(CloudSpeechConfig updated) {
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

  testWidgets('ModelSection Cloud BYOK & VoiceSection (ElevenLabs + OpenAI) tidak overflow di 320 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final profile = AiProviderProfile(
      id: 1,
      profileKey: 'gemini_1',
      name: 'Google Gemini',
      providerType: LlmProviderType.google,
      modelId: 'gemini-2.5-flash',
    );
    final settings = AppSettings(
      aiMode: AiMode.cloud,
      activeCloudProfileId: 1,
      ttsEnabled: true,
      ttsBackend: 'elevenlabs',
      sttBackend: 'openai',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(() => _TestSettingsNotifier(settings)),
          appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
          aiProviderProfilesProvider.overrideWith(
            () => _TestProfilesNotifier([profile]),
          ),
          cloudSpeechConfigProvider.overrideWith(
            () => _TestSpeechConfigNotifier(CloudSpeechConfig()),
          ),
          secretStoreProvider.overrideWithValue(InMemorySecretStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ListView(
              children: [
                ModelSection(settings: settings),
                VoiceSection(settings: settings),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Google Gemini · gemini-2.5-flash'), findsOneWidget);
    expect(find.text('ElevenLabs'), findsNWidgets(2));
  });

  testWidgets('CloudProviderEditorSheet dan CloudSpeechConfigSheet tidak overflow di 320 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = AppSettings();
    final overrides = [
      appSettingsProvider.overrideWith(() => _TestSettingsNotifier(settings)),
      appStringsProvider.overrideWith((ref) => const EnglishStrings()),
      aiProviderProfilesProvider.overrideWith(() => _TestProfilesNotifier(const [])),
      cloudSpeechConfigProvider.overrideWith(
        () => _TestSpeechConfigNotifier(CloudSpeechConfig()),
      ),
      secretStoreProvider.overrideWithValue(InMemorySecretStore()),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CloudProviderEditorSheet(
              initialProfile: AiProviderProfile(
                profileKey: 'p1',
                name: 'Anthropic Proxy',
                providerType: LlmProviderType.anthropic,
                modelId: 'claude-sonnet-4-6',
              ),
              isNew: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: CloudSpeechConfigSheet(provider: 'elevenlabs'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Cek juga provider OpenAI & Google dan Bahasa Indonesia di 320 dp.
    final idOverrides = [
      appSettingsProvider.overrideWith(() => _TestSettingsNotifier(settings)),
      appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      aiProviderProfilesProvider.overrideWith(() => _TestProfilesNotifier(const [])),
      cloudSpeechConfigProvider.overrideWith(
        () => _TestSpeechConfigNotifier(CloudSpeechConfig()),
      ),
      secretStoreProvider.overrideWithValue(InMemorySecretStore()),
    ];
    for (final speechProvider in const ['openai', 'google']) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: idOverrides,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: CloudSpeechConfigSheet(provider: speechProvider),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

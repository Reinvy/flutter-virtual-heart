// Widget test — CompanionHubScreen: status persona, mood, memori, & starter -> Chat.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:virtual_heart/core/design/app_theme.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/core/router/app_router.dart';
import 'package:virtual_heart/features/chat/chat_controller.dart';
import 'package:virtual_heart/features/chat/chat_models.dart';
import 'package:virtual_heart/features/chat/chat_screen.dart';
import 'package:virtual_heart/features/chat/mood_provider.dart';
import 'package:virtual_heart/features/hub/companion_hub_screen.dart';
import 'package:virtual_heart/features/memory/memory_controller.dart';
import 'package:virtual_heart/features/persona/persona_controller.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/memory_fact.dart';
import 'package:virtual_heart/models/mood_state.dart';
import 'package:virtual_heart/models/persona_config.dart';
import 'package:virtual_heart/services/ai/model_ready_provider.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class _TestSettingsNotifier extends AppSettingsNotifier {
  _TestSettingsNotifier(this.value);
  final AppSettings value;

  @override
  AppSettings build() => value;
}

class _TestPersonaNotifier extends PersonaNotifier {
  _TestPersonaNotifier(this.value);
  final PersonaConfig? value;

  @override
  PersonaConfig? build() => value;
}

class _TestMoodNotifier extends MoodNotifier {
  _TestMoodNotifier(this.value);
  final MoodState value;

  @override
  MoodState build() => value;
}

class _TestMemoryNotifier extends MemoryFactsNotifier {
  _TestMemoryNotifier(this.value);
  final List<MemoryFact> value;

  @override
  List<MemoryFact> build() => value;
}

class _TestChatNotifier extends ChatNotifier {
  @override
  ChatState build() => const ChatState(messages: []);
}

class _TestModelReadyNotifier extends ModelReadyNotifier {
  @override
  bool build() => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('menampilkan status persona, memori, dan tap starter mengisi input chat', (
    tester,
  ) async {
    final settings = AppSettings(
      isAgeVerified: true,
      isOnboardingDone: true,
      isPersonaSetup: true,
      modelVariant: 'gemma.litertlm',
    );
    final persona = PersonaConfig(
      name: 'Luna',
      nicknameForUser: 'Kai',
      avatarId: 'gf_1',
    );
    final mood = MoodState(current: MoodType.happy, intensity: 0.8);
    final facts = [
      MemoryFact(
        category: MemoryCategory.personal,
        key: 'minuman favorit',
        value: 'matcha hangat',
      ),
    ];

    final router = GoRouter(
      initialLocation: AppRoutes.hub,
      routes: [
        GoRoute(
          path: AppRoutes.hub,
          builder: (_, _) => const CompanionHubScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (_, _) => const ChatScreen(),
        ),
        GoRoute(
          path: AppRoutes.memory,
          builder: (_, _) => const Scaffold(body: Text('MEMORY_TAB')),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const Scaffold(body: Text('SETTINGS_TAB')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(() => _TestSettingsNotifier(settings)),
          appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
          personaProvider.overrideWith(() => _TestPersonaNotifier(persona)),
          moodProvider.overrideWith(() => _TestMoodNotifier(mood)),
          memoryFactsProvider.overrideWith(() => _TestMemoryNotifier(facts)),
          chatProvider.overrideWith(_TestChatNotifier.new),
          modelReadyProvider.overrideWith(_TestModelReadyNotifier.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsOneWidget);

    const starter1 =
        'Ceritakan harimu hari ini, apakah ada hal kecil yang menyenangkan?';
    expect(find.text(starter1), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('1 kenangan tersimpan'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 kenangan tersimpan'), findsOneWidget);
    expect(find.text('minuman favorit: matcha hangat'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hub-starter-0')),
      -160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('hub-starter-0')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.chat);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, starter1);
  });
}

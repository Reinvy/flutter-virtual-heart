// Widget test — ChatBubble (docs/DESIGN.md §3.3)
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/design/app_theme.dart';
import 'package:virtual_heart/core/design/tokens/app_colors.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/chat/mood_provider.dart';
import 'package:virtual_heart/features/chat/widgets/chat_bubble.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/message.dart';
import 'package:virtual_heart/models/mood_state.dart';
import 'package:virtual_heart/models/persona_config.dart';

class _FakeMoodNotifier extends MoodNotifier {
  @override
  MoodState build() => MoodState();
}

class _TestSettingsNotifier extends AppSettingsNotifier {
  _TestSettingsNotifier(this.value);
  final AppSettings value;

  @override
  AppSettings build() => value;
}

Widget wrap(Widget child) {
  return ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(() => _TestSettingsNotifier(AppSettings())),
      appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      moodProvider.overrideWith(_FakeMoodNotifier.new),
    ],
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );
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

  testWidgets('bubble user: warna solid userBubbleBg tanpa gradien', (tester) async {
    final msg = Message(role: MessageRole.user, content: 'Halo sayang');
    await tester.pumpWidget(wrap(ChatBubble(message: msg)));
    await tester.pumpAndSettle();

    expect(find.text('Halo sayang'), findsOneWidget);

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('chat-bubble-user')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, AppColors.userBubbleBg);
  });

  testWidgets('bubble AI: markdown dan nama persona dirender di editorial thread', (tester) async {
    final msg = Message(role: MessageRole.assistant, content: '**Hai!** Apa kabar?');
    final persona = PersonaConfig(name: 'Luna', avatarId: 'gf_1');
    await tester.pumpWidget(wrap(ChatBubble(message: msg, persona: persona)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chat-bubble-assistant')), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.textContaining('Hai!'), findsOneWidget);
  });

  testWidgets('tap bubble menampilkan timestamp', (tester) async {
    final msg = Message(
      role: MessageRole.user,
      content: 'Pesan',
      timestamp: DateTime(2026, 8, 25, 9, 5),
    );
    await tester.pumpWidget(wrap(ChatBubble(message: msg)));
    await tester.pumpAndSettle();

    expect(find.text('09:05'), findsNothing);
    await tester.tap(find.text('Pesan'));
    await tester.pumpAndSettle();
    expect(find.text('09:05'), findsOneWidget);
  });

  testWidgets('gambar markdown tidak dirender (privasi jaringan)', (tester) async {
    final msg = Message(
      role: MessageRole.assistant,
      content: 'Lihat ini ![foto](https://example.com/a.png) ya',
    );
    await tester.pumpWidget(wrap(ChatBubble(message: msg)));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('Lihat ini'), findsOneWidget);
    expect(find.textContaining('https://example.com'), findsNothing);
  });

  testWidgets('tombol speaker muncul untuk AI jika onSpeak diberikan', (tester) async {
    final msg = Message(role: MessageRole.assistant, content: 'Halo');
    await tester.pumpWidget(wrap(ChatBubble(message: msg, onSpeak: () {})));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });
}

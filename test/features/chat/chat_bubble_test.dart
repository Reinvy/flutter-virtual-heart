// Widget test — ChatBubble (docs/DESIGN.md §3.3)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/design/tokens/app_colors.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/chat/mood_provider.dart';
import 'package:virtual_heart/features/chat/widgets/chat_bubble.dart';
import 'package:virtual_heart/features/settings/settings_controller.dart';
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
    child: MaterialApp(home: Scaffold(body: child)),
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

  testWidgets('bubble user: warna primary (DESIGN §3.3)', (tester) async {
    final msg = Message(role: MessageRole.user, content: 'Halo sayang');
    await tester.pumpWidget(wrap(ChatBubble(message: msg)));
    await tester.pumpAndSettle();

    expect(find.text('Halo sayang'), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.primary);
  });

  testWidgets('bubble AI: markdown dirender', (tester) async {
    final msg = Message(role: MessageRole.assistant, content: '**Hai!** Apa kabar?');
    final persona = PersonaConfig(name: 'Luna', avatarId: 'gf_1');
    await tester.pumpWidget(wrap(ChatBubble(message: msg, persona: persona)));
    await tester.pumpAndSettle();

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

  testWidgets('tombol speaker muncul untuk AI jika onSpeak diberikan', (tester) async {
    final msg = Message(role: MessageRole.assistant, content: 'Halo');
    await tester.pumpWidget(wrap(ChatBubble(message: msg, onSpeak: () {})));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });
}

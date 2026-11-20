// Widget & controller test — regresi alur ChatNotifier (Lokal + Cloud BYOK) + InputBar isVoice.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:objectbox/objectbox.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/chat/chat_controller.dart';
import 'package:virtual_heart/features/chat/chat_models.dart';
import 'package:virtual_heart/features/chat/widgets/input_bar.dart';
import 'package:virtual_heart/models/ai_provider_profile.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/cloud_speech_config.dart';
import 'package:virtual_heart/models/memory_fact.dart';
import 'package:virtual_heart/models/message.dart';
import 'package:virtual_heart/models/mood_state.dart';
import 'package:virtual_heart/models/persona_config.dart';
import 'package:virtual_heart/services/ai/genkit/genkit_cloud_client.dart';
import 'package:virtual_heart/services/ai/memory_extractor.dart';
import 'package:virtual_heart/services/ai/model_service.dart';
import 'package:virtual_heart/services/ai/prompt_builder.dart';
import 'package:virtual_heart/services/ai/secret_store.dart';
import 'package:virtual_heart/services/database/objectbox_provider.dart';
import 'package:virtual_heart/services/database/objectbox_service.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class _FakeBox<T> implements Box<T> {
  _FakeBox(this._getId, this._setId, [List<T>? seed]) {
    if (seed != null) _items.addAll(seed);
  }

  final int Function(T) _getId;
  final void Function(T, int) _setId;
  final List<T> _items = [];
  int _nextId = 1;

  @override
  List<T> getAll() => List.of(_items);

  @override
  int put(T object, {PutMode mode = PutMode.put}) {
    var id = _getId(object);
    if (id == 0) {
      while (_items.any((e) => _getId(e) == _nextId)) {
        _nextId++;
      }
      id = _nextId++;
      _setId(object, id);
    }
    final idx = _items.indexWhere((e) => _getId(e) == id);
    if (idx >= 0) {
      _items[idx] = object;
    } else {
      _items.add(object);
    }
    return id;
  }

  @override
  List<int> putMany(List<T> objects, {PutMode mode = PutMode.put}) =>
      [for (final o in objects) put(o, mode: mode)];

  @override
  int removeMany(List<int> ids) {
    final before = _items.length;
    _items.removeWhere((e) => ids.contains(_getId(e)));
    return before - _items.length;
  }

  @override
  int removeAll() {
    final count = _items.length;
    _items.clear();
    return count;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeObjectBoxService implements ObjectBoxService {
  _FakeObjectBoxService({
    List<Message>? messages,
    AppSettings? settings,
    List<AiProviderProfile>? profiles,
  }) : messageBox = _FakeBox<Message>(
         (m) => m.id,
         (m, id) => m.id = id,
         messages,
       ),
       appSettingsBox = _FakeBox<AppSettings>(
         (s) => s.id,
         (s, id) => s.id = id,
         settings == null ? null : [settings],
       ),
       aiProviderProfileBox = _FakeBox<AiProviderProfile>(
         (p) => p.id,
         (p, id) => p.id = id,
         profiles,
       ),
       cloudSpeechConfigBox = _FakeBox<CloudSpeechConfig>(
         (c) => c.id,
         (c, id) => c.id = id,
       );

  @override
  final _FakeBox<PersonaConfig> personaBox = _FakeBox<PersonaConfig>(
    (p) => p.id,
    (p, id) => p.id = id,
    [PersonaConfig(id: 1, name: 'Luna', nicknameForUser: 'Kai')],
  );

  @override
  final _FakeBox<Message> messageBox;

  @override
  final _FakeBox<MemoryFact> memoryFactBox = _FakeBox<MemoryFact>(
    (f) => f.id,
    (f, id) => f.id = id,
  );

  @override
  final _FakeBox<MoodState> moodStateBox = _FakeBox<MoodState>(
    (m) => m.id,
    (m, id) => m.id = id,
  );

  @override
  final _FakeBox<AppSettings> appSettingsBox;

  @override
  final _FakeBox<AiProviderProfile> aiProviderProfileBox;

  @override
  final _FakeBox<CloudSpeechConfig> cloudSpeechConfigBox;

  @override
  AppSettings getOrCreateSettings() {
    final all = appSettingsBox.getAll();
    if (all.isEmpty) {
      final d = AppSettings().normalized();
      appSettingsBox.put(d);
      return d;
    }
    return all.first.normalized();
  }

  @override
  CloudSpeechConfig getOrCreateCloudSpeechConfig() {
    final all = cloudSpeechConfigBox.getAll();
    if (all.isEmpty) {
      final d = CloudSpeechConfig().normalized();
      cloudSpeechConfigBox.put(d);
      return d;
    }
    return all.first.normalized();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeModelService extends ModelServiceNotifier {
  _FakeModelService({
    required this.tokens,
    this.tokenDelay = Duration.zero,
  });

  final List<String> tokens;
  final Duration tokenDelay;
  bool stopped = false;
  int summaryCalls = 0;

  @override
  Future<ModelStatus> build() async =>
      const ModelStatus(ready: true, modelName: 'fake-model');

  @override
  Future<void> stopGeneration() async {
    stopped = true;
  }

  @override
  Stream<String> generateResponseStream(
    String fullPrompt, {
    bool Function()? isCancelled,
  }) async* {
    for (final t in tokens) {
      if (stopped || isCancelled?.call() == true) return;
      if (tokenDelay > Duration.zero) await Future<void>.delayed(tokenDelay);
      if (stopped || isCancelled?.call() == true) return;
      yield t;
    }
  }

  @override
  Future<String> generateResponse(String fullPrompt) async {
    summaryCalls++;
    return 'Ringkasan percakapan hangat.';
  }
}

class _NoopMemoryExtractor extends MemoryExtractor {
  const _NoopMemoryExtractor();

  @override
  Future<List<MemoryFact>> extractFacts(
    String conversation,
    Future<String> Function(String prompt) generateFn,
  ) async => const [];
}

void main() {
  testWidgets('InputBar mengirim teks sebelum mengosongkan controller sehingga isVoice terjaga', (
    tester,
  ) async {
    final ctrl = TextEditingController();
    String? voiceDraft = 'Halo dari suara';
    bool? sentIsVoice;
    String? sentText;

    ctrl.addListener(() {
      if (voiceDraft != null && ctrl.text != voiceDraft) {
        voiceDraft = null;
      }
    });
    ctrl.text = voiceDraft!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: InputBar(
              controller: ctrl,
              onSend: (text) {
                sentText = text;
                sentIsVoice = voiceDraft != null;
                voiceDraft = null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(sentText, 'Halo dari suara');
    expect(sentIsVoice, isTrue);
    expect(ctrl.text, isEmpty);
    ctrl.dispose();
  });

  test('retryLastResponse menghapus pesan parsial asisten sebelumnya dan menggantinya', () async {
    final db = _FakeObjectBoxService(
      messages: [
        Message(id: 1, role: MessageRole.user, content: 'Hai Luna'),
        Message(id: 2, role: MessageRole.assistant, content: 'Parsial gagal'),
      ],
    );
    final model = _FakeModelService(tokens: ['Jawaban ', 'baru']);
    final container = ProviderContainer(
      overrides: [
        objectBoxServiceProvider.overrideWithValue(db),
        modelServiceProvider.overrideWith(() => model),
        memoryExtractorProvider.overrideWithValue(const _NoopMemoryExtractor()),
        appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(modelServiceProvider.future);
    await container.read(chatProvider.notifier).retryLastResponse();

    final state = container.read(chatProvider);
    expect(state.messages.map((m) => m.content).toList(), ['Hai Luna', 'Jawaban baru']);
    expect(db.messageBox.getAll().map((m) => m.content).toList(), [
      'Hai Luna',
      'Jawaban baru',
    ]);
  });

  test('summarization menyimpan summaryMessageCount sesuai pesan tak-terblokir', () async {
    final seed = <Message>[
      for (var i = 0; i < PromptBuilder.summarizationInterval - 2; i++)
        Message(
          id: i + 1,
          role: i.isEven ? MessageRole.user : MessageRole.assistant,
          content: 'msg $i',
        ),
      for (var i = 0; i < 5; i++)
        Message(
          id: 100 + i,
          role: MessageRole.user,
          content: 'blocked $i',
          isBlocked: true,
        ),
    ];
    final db = _FakeObjectBoxService(
      messages: seed,
      settings: AppSettings(id: 1, isAgeVerified: true, isOnboardingDone: true, isPersonaSetup: true),
    );
    final model = _FakeModelService(tokens: ['Balasan ', 'lengkap']);
    final container = ProviderContainer(
      overrides: [
        objectBoxServiceProvider.overrideWithValue(db),
        modelServiceProvider.overrideWith(() => model),
        memoryExtractorProvider.overrideWithValue(const _NoopMemoryExtractor()),
        appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(modelServiceProvider.future);
    await container.read(chatProvider.notifier).sendMessage('Pesan pemicu ringkasan');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final settings = container.read(appSettingsProvider);
    expect(model.summaryCalls, 1);
    expect(settings.summaryMessageCount, PromptBuilder.summarizationInterval);
    expect(settings.conversationSummary, 'Ringkasan percakapan hangat.');
  });

  test('cancelGeneration menghentikan generasi dan tidak memicu summarization', () async {
    final seed = <Message>[
      for (var i = 0; i < PromptBuilder.summarizationInterval - 1; i++)
        Message(
          id: i + 1,
          role: i.isEven ? MessageRole.user : MessageRole.assistant,
          content: 'msg $i',
        ),
    ];
    final db = _FakeObjectBoxService(
      messages: seed,
      settings: AppSettings(id: 1, isAgeVerified: true, isOnboardingDone: true, isPersonaSetup: true),
    );
    final model = _FakeModelService(
      tokens: ['Satu ', 'Dua ', 'Tiga '],
      tokenDelay: const Duration(milliseconds: 30),
    );
    final container = ProviderContainer(
      overrides: [
        objectBoxServiceProvider.overrideWithValue(db),
        modelServiceProvider.overrideWith(() => model),
        memoryExtractorProvider.overrideWithValue(const _NoopMemoryExtractor()),
        appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(modelServiceProvider.future);
    final sendFuture = container.read(chatProvider.notifier).sendMessage('Halo');
    await Future<void>.delayed(const Duration(milliseconds: 35));
    await container.read(chatProvider.notifier).cancelGeneration();
    await sendFuture;

    expect(model.stopped, isTrue);
    expect(model.summaryCalls, 0);
  });

  test('mode Cloud BYOK memakai GenkitCloudClient multi-turn & menghormati enableBackgroundTasks=false', () async {
    var httpCalls = 0;
    final profile = AiProviderProfile(
      id: 1,
      profileKey: 'openai_1',
      name: 'OpenRouter',
      providerType: LlmProviderType.openai,
      baseUrl: 'https://openrouter.ai/api/v1',
      modelId: 'openai/gpt-4o-mini',
      maxInputChars: 5000,
      enforceShortReply: false,
      enableBackgroundTasks: false,
    );
    final db = _FakeObjectBoxService(
      settings: AppSettings(
        id: 1,
        isAgeVerified: true,
        isOnboardingDone: true,
        isPersonaSetup: true,
        aiMode: AiMode.cloud,
        activeCloudProfileId: 1,
      ),
      profiles: [profile],
    );
    final secrets = InMemorySecretStore({
      SecretKeys.forLlmProfile('openai_1'): 'sk-or-test',
    });
    final cloudClient = GenkitCloudClient(
      httpClientFactory: () => MockClient.streaming((req, bodyStream) async {
        httpCalls++;
        await bodyStream.drain<void>();
        final sse = [
          'data: ${jsonEncode({
            'id': 'c1',
            'object': 'chat.completion.chunk',
            'created': 1700000000,
            'model': 'openai/gpt-4o-mini',
            'choices': [
              {'index': 0, 'delta': {'role': 'assistant', 'content': 'Halo dari Cloud!'}, 'finish_reason': 'stop'},
            ],
          })}\n\n',
          'data: [DONE]\n\n',
        ];
        return http.StreamedResponse(
          Stream.fromIterable(sse.map(utf8.encode)),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
    );

    final container = ProviderContainer(
      overrides: [
        objectBoxServiceProvider.overrideWithValue(db),
        secretStoreProvider.overrideWithValue(secrets),
        genkitCloudClientProvider.overrideWithValue(cloudClient),
        appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      ],
    );
    addTearDown(container.dispose);

    final status = await container.read(modelServiceProvider.future);
    expect(status.ready, isTrue);
    expect(status.mode, AiMode.cloud);

    // Kirim input > 2000 karakter (diizinkan oleh maxInputChars=5000 di Cloud).
    final longMessage = 'Cerita panjang ' * 160; // ~2400 char
    await container.read(chatProvider.notifier).sendMessage(longMessage);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final state = container.read(chatProvider);
    expect(state.error, isNull);
    expect(state.messages.length, 2);
    expect(state.messages.first.content.length, greaterThan(2000));
    expect(state.messages.last.content, 'Halo dari Cloud!');
    // enableBackgroundTasks == false → hanya 1 panggilan HTTP (chat utama), tidak ada ekstraksi memori.
    expect(httpCalls, 1);
  });

  test('mode Cloud BYOK memetakan HTTP 401 menjadi ChatErrorKind.authError', () async {
    final profile = AiProviderProfile(
      id: 1,
      profileKey: 'openai_auth',
      name: 'OpenAI',
      providerType: LlmProviderType.openai,
      modelId: 'gpt-4o-mini',
    );
    final db = _FakeObjectBoxService(
      settings: AppSettings(
        id: 1,
        isAgeVerified: true,
        isOnboardingDone: true,
        isPersonaSetup: true,
        aiMode: AiMode.cloud,
        activeCloudProfileId: 1,
      ),
      profiles: [profile],
    );
    final secrets = InMemorySecretStore({
      SecretKeys.forLlmProfile('openai_auth'): 'bad-key',
    });
    final cloudClient = GenkitCloudClient(
      httpClientFactory: () => MockClient(
        (_) async => http.Response(
          jsonEncode({'error': {'message': 'Incorrect API key'}}),
          401,
        ),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        objectBoxServiceProvider.overrideWithValue(db),
        secretStoreProvider.overrideWithValue(secrets),
        genkitCloudClientProvider.overrideWithValue(cloudClient),
        appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(modelServiceProvider.future);
    await container.read(chatProvider.notifier).sendMessage('Halo');

    final state = container.read(chatProvider);
    expect(state.error?.kind, ChatErrorKind.authError);
    expect(state.error?.canRetry, isTrue);
  });
}

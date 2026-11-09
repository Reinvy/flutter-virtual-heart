# ARCHITECTURE — Struktur Runtime VirtualHeart

Dokumen ini menjelaskan **kondisi saat ini**. Detail skema data ada di
[`DATA_MODEL.md`](DATA_MODEL.md), detail AI di [`AI_PIPELINE.md`](AI_PIPELINE.md).

## 1. Init flow (`lib/main.dart`)

```
WidgetsFlutterBinding.ensureInitialized()
  → SharedPreferences           # baca token HuggingFace opsional ('hf_token')
  → FlutterEdgeAi.initialize(   # engine inference + backend speech
        inferenceEngines: [MediaPipeEngine(), LiteRtLmEngine()],
        sttBackends:      [LiteRtSttBackend()],
        ttsBackends:      [LiteRtTtsBackend()],
        huggingFaceToken: <token|nul>, maxDownloadRetries: 10)
  → NotificationService().initialize()   # plugin + zona waktu lokal (best-effort)
  → ObjectBoxService.create()            # openStore + 5 box
  → runApp(ProviderScope(overrides: [objectBoxServiceProvider], child: VirtualHeartApp))
```

Kegagalan inisialisasi engine AI adalah fatal (dibutuhkan seluruh fitur). Kegagalan inisialisasi
notifikasi hanya di-log (`AppLogger.error`) — aplikasi tetap jalan tanpa notifikasi.

## 2. Tree `lib/` (current-state)

```
lib/
├── main.dart                    # composition root
├── app.dart                     # MaterialApp.router, locale, tap notifikasi
├── core/
│   ├── design/
│   │   ├── app_theme.dart       # ThemeData light/dark
│   │   ├── app_theme_provider.dart
│   │   ├── components/          # primary_button, secondary_button, app_icon_button,
│   │   │                        # section_card, confirm_dialog, empty_state,
│   │   │                        # sakura_background, sakura_divider, speaker_button
│   │   └── tokens/              # app_colors, app_sizes, app_durations, text_styles
│   ├── errors/app_logger.dart   # satu-satunya logger
│   ├── l10n/app_strings.dart    # AppStrings + IndonesianStrings + EnglishStrings
│   ├── router/app_router.dart   # GoRouter + resolveRedirect (fungsi murni)
│   └── utils/                   # date_formatter, wav_pcm
├── models/
│   ├── app_settings.dart        # @Entity AppSettings
│   ├── message.dart             # @Entity Message
│   ├── memory_fact.dart         # @Entity MemoryFact
│   ├── mood_state.dart          # @Entity MoodState
│   ├── persona_config.dart      # @Entity PersonaConfig
│   ├── objectbox_provider.dart  # objectBoxServiceProvider
│   ├── objectbox.g.dart         # GENERATED — jangan diedit
│   └── objectbox-model.json     # GENERATED — jangan diedit
├── services/
│   ├── ai/
│   │   ├── model_service.dart        # ModelServiceNotifier (install + inference)
│   │   ├── model_catalog.dart        # 5 model LLM
│   │   ├── speech_model_catalog.dart # 3 TTS + 1 STT
│   │   ├── prompt_builder.dart       # system prompt, full prompt, summarization
│   │   ├── memory_extractor.dart     # parser "FACT: ..." (tanpa dependensi engine)
│   │   └── content_safety.dart       # gate input/output
│   ├── database/objectbox_service.dart
│   ├── mood_service.dart             # MoodService (transisi mood)
│   ├── mood_store.dart               # kontrak Box<MoodState>
│   ├── notification_service.dart     # plugin + zona waktu + tap stream
│   ├── notification_time.dart        # nextInstanceOf (fungsi murni)
│   ├── stt_service.dart              # backend 'gemma' | 'system'
│   └── tts_service.dart              # backend 'gemma' | 'system'
└── features/
    ├── onboarding/     # splash, age_gate, onboarding
    ├── persona/        # setup, edit sheet, profile sheet, avatar_catalog
    ├── model/          # model_download_screen, model_ready_provider
    ├── chat/           # chat_screen, chat_controller, mood_provider, widgets/
    ├── memory/         # memory_screen, memory_controller
    ├── settings/       # settings_screen + widget section
    └── notifications/  # app_lifecycle_observer, notification_controller
```

## 3. Provider (15)

| Provider | Tipe | State | File |
| --- | --- | --- | --- |
| `objectBoxServiceProvider` | `Provider` (di-override di `main`) | `ObjectBoxService` | `models/objectbox_provider.dart` |
| `appSettingsProvider` | `NotifierProvider` | `AppSettings` | `features/settings/settings_controller.dart` |
| `themeModeProvider` | `NotifierProvider` | `ThemeMode` | `core/design/app_theme_provider.dart` |
| `appStringsProvider` | `Provider` | `AppStrings` | `core/l10n/app_strings.dart` |
| `routerProvider` | `Provider` | `GoRouter` | `core/router/app_router.dart` |
| `personaProvider` | `NotifierProvider` | `PersonaConfig?` | `features/persona/persona_controller.dart` |
| `modelReadyProvider` | `NotifierProvider` | `bool` | `features/model/model_ready_provider.dart` |
| `modelServiceProvider` | `AsyncNotifierProvider` | `ModelStatus` | `services/ai/model_service.dart` |
| `memoryExtractorProvider` | `Provider` | `MemoryExtractor` | `services/ai/memory_extractor.dart` |
| `chatProvider` | `NotifierProvider` | `ChatState` | `features/chat/chat_controller.dart` |
| `memoryFactsProvider` | `NotifierProvider` | `List<MemoryFact>` | `features/memory/memory_controller.dart` |
| `moodServiceProvider` | `Provider` | `MoodService` | `services/mood_service.dart` |
| `moodProvider` | `NotifierProvider` | `MoodState` | `features/chat/mood_provider.dart` |
| `notificationServiceProvider` | `Provider` | `NotificationService` | `services/notification_service.dart` |
| `notificationProvider` | `AsyncNotifierProvider` | `void` | `features/notifications/notification_controller.dart` |

## 4. Routing

`AppRoutes`: `/splash`, `/age-gate`, `/onboarding`, `/persona-setup`,
`/model-download`, `/chat`, `/memory`, `/settings`.

`resolveRedirect({path, settings, isModelReady})` adalah fungsi murni (dites di
`test/core/router_guard_test.dart`):

| Kondisi | Hasil |
| --- | --- |
| `path == /splash` | `null` (splash memutuskan sendiri) |
| `!isAgeVerified` | `/age-gate` (null bila sudah di sana) |
| `!isOnboardingDone` | `/onboarding` |
| `!isPersonaSetup` | `/persona-setup` |
| `!isModelReady` | `/model-download` |
| path ∈ {`/age-gate`, `/onboarding`, `/persona-setup`} & semua lolos | `/chat` |
| selain itu | `null` |

`/model-download` **tidak** punya bypass: gate umur/onboarding/persona tetap berlaku.
`routerProvider` memakai `refreshListenable` yang mendengarkan `appSettingsProvider` dan
`modelReadyProvider`, sehingga redirect dievaluasi ulang saat settings/kesiapan model berubah.

## 5. Alur data chat

```
InputBar.onSend
  → ChatNotifier.sendMessage(text, isVoice:)
      ├─ persist Message(user) → state.messages
      ├─ ContentSafety.filterInput  → blocked? tampilkan redirect, stop
      ├─ PromptBuilder.buildSystemPrompt(persona, mood, memoryFacts, summary, language)
      ├─ PromptBuilder.buildFullPrompt(system, history, text)   # ≤20 pesan terakhir
      ├─ tandai lastReferencedAt fakta memori yang dipakai
      ├─ ModelServiceNotifier.generateResponseStream(fullPrompt) → token demi token
      ├─ ContentSafety.validateOutput → finalContent
      ├─ persist Message(assistant, mood: <mood aktif>) → state.messages
      └─ Future.microtask(_postProcess):
            ├─ MemoryExtractor.extractFacts → merge by key (sourceSnippet = pesan user)
            ├─ setiap 30 pesan: summarize → appSettings.setConversationSummary
            └─ MoodService.updateMoodFromConversation → moodProvider.refresh
```

`ModelServiceNotifier` membuat satu `InferenceChat` per permintaan (`openChat`) dan menutupnya
di `finally`, sehingga tidak ada state percakapan yang bocor antar-request.

## 6. Service & lifetime

| Service | Lifetime | Catatan |
| --- | --- | --- |
| `ObjectBoxService` | singleton proses | `close()` tidak dipanggil (proses = lifetime app) |
| `ModelServiceNotifier` | provider | memegang `InferenceModel` aktif + `CancelToken` download |
| `MoodService` | provider baru per instance | stateless terhadap UI, baca/tulis `Box<MoodState>` |
| `SttService` | singleton (`factory`) | `AudioRecorder` + `SpeechToText` hidup sepanjang proses |
| `TtsService` | singleton (`factory`) | `FlutterTts` + `FlutterPcmSound` dilepas di `stop()` |
| `NotificationService` | singleton (`factory`) | plugin, zona waktu, `StreamController` broadcast tap |
| `AppLogger` | static | hanya mencetak di debug build |

## 7. Aturan layer

- `core/` tidak mengimpor `features/`, kecuali `core/router` (composition root),
  `core/l10n` (butuh `appSettingsProvider`), dan `core/design` (token/komponen).
- `services/` tidak mengimpor widget.
- `models/` tidak mengimpor `services/` atau `features/`.
- `features/` boleh mengimpor `core/`, `models/`, `services/`.

Lihat [`DATA_MODEL.md`](DATA_MODEL.md) untuk skema & [`AI_PIPELINE.md`](AI_PIPELINE.md) untuk
detail inference.

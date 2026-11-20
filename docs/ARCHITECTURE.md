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
  → ObjectBoxService.create()            # openStore + 7 box (pulih dari store korup)
  → runApp(ProviderScope(overrides: [objectBoxServiceProvider], child: VirtualHeartApp))
```

Seluruh bootstrap dibungkus `try/catch` serta dilengkapi global error hook (`FlutterError.onError`
dan `PlatformDispatcher.instance.onError` → `AppLogger.error`): bila engine AI atau database
gagal dibuka, aplikasi merender `BootstrapErrorApp` (layar darurat dua bahasa tanpa `GoogleFonts`
atau `ThemeExtension`, dengan tombol Tutup), bukan jendela kosong. Kegagalan inisialisasi
notifikasi hanya di-log (`AppLogger.error`) — aplikasi tetap jalan tanpa notifikasi.
## 2. Tree `lib/` (current-state)

```
lib/
├── main.dart                    # composition root + guard bootstrap
├── bootstrap_error_app.dart     # layar darurat bila bootstrap gagal
├── app.dart                     # MaterialApp.router, locale, tap notifikasi
├── core/
│   ├── design/
│   │   ├── app_theme.dart            # ThemeData ter-cache lightFor/darkFor per AppThemeStyle
│   │   ├── active_shell_tab_provider.dart
│   │   ├── mood_visuals.dart         # moodEmoji + moodLabel + moodColor bersama
│   │   ├── components/               # app_scaffold, app_background, main_shell_scaffold,
│   │   │                             # resonance_mark, app_icon_badge, app_sheet, sheet_header,
│   │   │                             # primary_button, secondary_button, app_icon_button,
│   │   │                             # section_card, confirm_dialog, empty_state, speaker_button,
│   │   │                             # double_back_exit_scope
│   │   └── tokens/                   # app_colors (AppPalette/AppPalettes), app_effects (AppBorders),
│   │                                 # app_sizes, app_durations, text_styles
│   ├── errors/app_logger.dart   # satu-satunya logger
│   ├── l10n/app_strings.dart    # AppStrings + IndonesianStrings + EnglishStrings
│   ├── router/app_router.dart   # GoRouter + resolveRedirect (fungsi murni)
│   └── utils/                   # async_fifo_lock, date_formatter, wav_pcm
├── models/
│   ├── ai_provider_profile.dart # @Entity AiProviderProfile (BYOK LLM + parameter)
│   ├── app_settings.dart        # @Entity AppSettings (mode local/cloud, speech backends)
│   ├── cloud_speech_config.dart # @Entity CloudSpeechConfig (ElevenLabs/OpenAI/Google)
│   ├── message.dart             # @Entity Message (termasuk isBlocked)
│   ├── memory_fact.dart         # @Entity MemoryFact
│   ├── mood_state.dart          # @Entity MoodState
│   ├── persona_config.dart      # @Entity PersonaConfig
│   ├── objectbox.g.dart         # GENERATED — jangan diedit
│   └── objectbox-model.json     # GENERATED — jangan diedit
├── services/
│   ├── ai/
│   │   ├── genkit/
│   │   │   ├── provider_config_builder.dart # URL normalizer & sanitizer opsi provider
│   │   │   ├── compat_http_client.dart      # strip stream_options, header, cancel token
│   │   │   ├── elevenlabs_plugin.dart       # ElevenLabsGenkitPlugin (TTS/STT/voices)
│   │   │   └── genkit_cloud_client.dart     # GenkitCloudClient + genkitCloudClientProvider
│   │   ├── ai_provider_controller.dart      # CRUD profil BYOK, active profile, speech config
│   │   ├── cloud_provider_catalog.dart      # preset provider Cloud LLM & speech
│   │   ├── secret_store.dart                # SecretStore terenkripsi (flutter_secure_storage)
│   │   ├── model_service.dart               # ModelServiceNotifier hybrid (Lokal + Cloud BYOK)
│   │   ├── model_ready_provider.dart        # modelReadyProvider (wiring router)
│   │   ├── model_catalog.dart               # 5 model LLM lokal
│   │   ├── speech_model_catalog.dart        # 3 TTS + 1 STT lokal
│   │   ├── prompt_builder.dart              # PromptLimits (Lokal & Cloud), buildCloudMessages
│   │   ├── memory_extractor.dart            # parser "FACT: ..." (tanpa dependensi engine)
│   │   ├── memory_fact_merger.dart          # mergeFacts (fungsi murni)
│   │   └── content_safety.dart              # gate input/output → SafetyRedirect
│   ├── database/
│   │   ├── objectbox_service.dart    # open + pemulihan store korup (7 box)
│   │   └── objectbox_provider.dart   # objectBoxServiceProvider
│   ├── settings/settings_service.dart # appSettingsProvider + reset flows (termasuk BYOK)
│   ├── mood_service.dart             # MoodService (transisi mood)
│   ├── mood_store.dart               # kontrak Box<MoodState>
│   ├── notification_service.dart     # plugin + zona waktu + tap stream
│   ├── notification_time.dart        # nextInstanceOf (fungsi murni)
│   ├── stt_service.dart              # backend 'system'|'gemma'|'elevenlabs'|'openai'|'google'
│   └── tts_service.dart              # backend 'system'|'gemma'|'elevenlabs'|'openai'|'google'
└── features/
    ├── hub/            # companion_hub_screen (beranda pendamping, starter, badge Lokal/Cloud)
    ├── onboarding/     # splash, age_gate, onboarding
    ├── persona/        # setup, edit sheet, profile sheet, avatar_catalog, persona_options
    ├── model/          # model_download_screen (tab Lokal & Cloud BYOK),
    │                   # cloud_provider_editor_sheet, model_error_text
    ├── chat/           # chat_screen, chat_controller, chat_models, mood_provider, widgets/
    ├── memory/         # memory_screen, memory_controller
    ├── settings/       # settings_screen, privacy_screen + widgets/ (section, row,
    │                   # permission_row, appearance, language, model, voice,
    │                   # cloud_speech_sheet, notifications, data_privacy, persona)
    └── notifications/  # app_lifecycle_observer, notification_controller
```

## 3. Provider (23)

| Provider | Tipe | State | File |
| --- | --- | --- | --- |
| `objectBoxServiceProvider` | `Provider` (di-override di `main`) | `ObjectBoxService` | `services/database/objectbox_provider.dart` |
| `secretStoreProvider` | `Provider` | `SecretStore` | `services/ai/secret_store.dart` |
| `genkitCloudClientProvider` | `Provider` | `GenkitCloudClient` | `services/ai/genkit/genkit_cloud_client.dart` |
| `appSettingsProvider` | `NotifierProvider` | `AppSettings` | `services/settings/settings_service.dart` |
| `aiProviderProfilesProvider` | `NotifierProvider` | `List<AiProviderProfile>` | `services/ai/ai_provider_controller.dart` |
| `activeCloudProfileProvider` | `Provider` | `AiProviderProfile?` | `services/ai/ai_provider_controller.dart` |
| `cloudSpeechConfigProvider` | `NotifierProvider` | `CloudSpeechConfig` | `services/ai/ai_provider_controller.dart` |
| `themeModeProvider` | `Provider` | `ThemeMode` | `core/design/app_theme_provider.dart` |
| `themeStyleProvider` | `Provider` | `AppThemeStyle` | `core/design/app_theme_provider.dart` |
| `activeShellTabProvider` | `NotifierProvider` | `int` | `core/design/active_shell_tab_provider.dart` |
| `appStringsProvider` | `Provider` | `AppStrings` | `core/l10n/app_strings.dart` |
| `routerProvider` | `Provider` | `GoRouter` | `core/router/app_router.dart` |
| `personaProvider` | `NotifierProvider` | `PersonaConfig?` | `features/persona/persona_controller.dart` |
| `modelReadyProvider` | `NotifierProvider` | `bool` | `services/ai/model_ready_provider.dart` |
| `modelServiceProvider` | `AsyncNotifierProvider` | `ModelStatus` | `services/ai/model_service.dart` |
| `memoryExtractorProvider` | `Provider` | `MemoryExtractor` | `services/ai/memory_extractor.dart` |
| `chatProvider` | `NotifierProvider` | `ChatState` | `features/chat/chat_controller.dart` |
| `pendingChatDraftProvider` | `NotifierProvider` | `String?` | `features/chat/chat_controller.dart` |
| `memoryFactsProvider` | `NotifierProvider` | `List<MemoryFact>` | `features/memory/memory_controller.dart` |
| `moodServiceProvider` | `Provider` | `MoodService` | `services/mood_service.dart` |
| `moodProvider` | `NotifierProvider` | `MoodState` | `features/chat/mood_provider.dart` |
| `notificationServiceProvider` | `Provider` | `NotificationService` | `services/notification_service.dart` |
| `notificationProvider` | `AsyncNotifierProvider` | `void` | `features/notifications/notification_controller.dart` |

## 4. Routing

`AppRoutes`: `/splash`, `/age-gate`, `/privacy`, `/onboarding`, `/persona-setup`,
`/model-download`, dan shell 4-tab (`StatefulShellRoute.indexedStack` via `MainShellScaffold`):
`/hub`, `/chat`, `/memory`, `/settings`.

`resolveRedirect({path, settings, isModelReady, queryParameters})` adalah fungsi murni (dites di
`test/core/router_guard_test.dart`):

| Kondisi | Hasil |
| --- | --- |
| `path == /splash` | `null` (splash memutuskan sendiri) |
| `path == /privacy` | `null` (kebijakan bisa dibaca sebelum menyetujui) |
| `!isAgeVerified` | `/age-gate` (null bila sudah di sana) |
| `!isOnboardingDone` | `/onboarding` |
| `!isPersonaSetup` | `/persona-setup` |
| `!isModelReady` | `/model-download` |
| path ∈ {`/age-gate`, `/onboarding`, `/persona-setup`} & semua lolos | `/hub` |
| `path == /model-download` & `queryParameters['auto'] == '1'` & semua lolos | `/hub` |
| selain itu | `null` |

`/model-download` **tidak** punya bypass: gate umur/onboarding/persona tetap berlaku, tetapi
rute ini tetap bisa dibuka saat model sudah siap (untuk mengganti model). Rute yang datang
otomatis dari timeout boot membawa `?auto=1` agar otomatis lanjut ke `/hub` bila model selesai
memuat di latar belakang. Rute tak dikenal dirender oleh `errorBuilder` yang terlokalisasi
dengan tombol kembali ke `/splash`.
`modelReadyProvider`, sehingga redirect dievaluasi ulang saat settings/kesiapan model berubah.

## 5. Alur data chat

```
InputBar.onSend
  → ChatNotifier.sendMessage(text, isVoice:)
      ├─ ContentSafety.filterInput                    # SEBELUM persist
      ├─ persist Message(user, isBlocked: hasil gate) → state.messages
      ├─ blocked? → Message(assistant, deflection AppStrings), stop (tanpa model/memori/mood)
      ├─ pilih PromptLimits: PromptLimits.local (Lokal) atau PromptLimits.forCloud(profile) (Cloud)
      ├─ PromptBuilder.buildSystemPrompt(persona, mood, fakta, summary, language, limits,
      │     enforceShortReply, customSystemPrompt)
      ├─ Mode Lokal: PromptBuilder.buildFullPrompt(system, history, text) → generateResponseStream
      ├─ Mode Cloud BYOK: PromptBuilder.buildCloudMessages(history, text, limits) →
      │     ModelServiceNotifier.generateChatStream → GenkitCloudClient.streamChat (multi-turn)
      │     ├─ antrean inferensi FIFO (chat/memori/ringkasan tidak tumpang tindih)
      │     └─ holdback 64 char: output terlarang tidak pernah terlihat
      ├─ ContentSafety.validateOutput → finalContent (deflection bila perlu)
      ├─ MoodService.updateMoodFromConversation(user, finalContent) → moodProvider.refresh
      ├─ persist Message(assistant, mood: <mood baru>) → state.messages
      ├─ tandai lastReferencedAt HANYA fakta yang dipakai (setelah sukses)
      └─ _enqueuePostProcess (serial; dilewati di Cloud bila enableBackgroundTasks=false):
            ├─ MemoryExtractor.extractFacts (pakai backgroundModelId bila diisi) → mergeFacts
            └─ bila ≥30 pesan baru: summarize → conversationSummary + summaryMessageCount
```

Kegagalan generasi dipetakan ke `ChatState.error` (`ChatErrorKind`: `modelUnavailable`,
`contextLimit`, `authError`, `rateLimited`, `timeout`, `invalidConfig`, `generationFailed`,
`interrupted`) lalu ditampilkan via `AppStrings` oleh `ChatScreen`, dengan aksi Coba Lagi/Dismiss.
`cancelGeneration()` menandai pembatalan, memanggil `ModelServiceNotifier.stopGeneration()`
(`InferenceChat.stopGeneration()` pada mode Lokal atau `CancellationToken.cancel()` + penutupan
HTTP client pada mode Cloud), lalu menunggu generasi + antrean post-process selesai.

Pada mode Lokal, `ModelServiceNotifier` membuat satu `InferenceChat` per permintaan (`openChat`)
dan menutupnya di `finally`, dengan `randomSeed` acak dan `maxOutputTokens: 512`. Pada mode
Cloud BYOK, aktivasi profil menutup model lokal native agar RAM bebas dan meneruskan seluruh
parameter profil ke `GenkitCloudClient`.

## 6. Service & lifetime

| Service | Lifetime | Catatan |
| --- | --- | --- |
| `ObjectBoxService` | singleton proses | 7 box; `close()` tidak dipanggil (proses = lifetime app) |
| `SecretStore` | provider (`SecureSecretStore`) | enkripsi API key BYOK via `flutter_secure_storage` (Keystore/Keychain) |
| `GenkitCloudClient` | provider | membangun instance `Genkit(isDevEnv: false, promptDir: null)` per panggilan untuk Google, Anthropic, OpenAI, dan `ElevenLabsGenkitPlugin` |
| `ModelServiceNotifier` | provider | orkestrator hybrid Lokal (`InferenceModel`/`InferenceChat`/`CancelToken`) & Cloud BYOK (`CancellationToken`); FIFO `AsyncFifoLock` + serialisasi `_engineTransition` |
| `SttService` | singleton (`factory`) | `AudioRecorder` + `SpeechToText` + transkripsi Cloud via `GenkitCloudClient` |
| `TtsService` | singleton (`factory`) | `FlutterTts` + `FlutterPcmSound` + `AudioPlayer` (`audioplayers`) untuk Cloud TTS dengan cleanup file sementara |
| `NotificationService` | singleton (`factory`) | plugin, zona waktu, `StreamController` broadcast tap |
| `AppLogger` | static | hanya mencetak di debug build; tidak pernah mencetak API key |

## 7. Aturan layer

- `core/` tidak mengimpor `features/`, kecuali `core/router` (composition root),
  `core/l10n` (butuh `appSettingsProvider`), dan `core/design` (token/komponen). `core/` boleh
  mengimpor `services/` hanya untuk wiring provider.
- `services/` tidak mengimpor widget maupun `features/`; provider bersama
  (`objectbox_provider`, `settings_service`, `model_ready_provider`) tinggal di `services/`.
- `models/` hanya berisi entity ObjectBox + file generated; tidak mengimpor `services/` atau
  `features/`.
- `features/` boleh mengimpor `core/`, `models/`, `services/`.

Lihat [`DATA_MODEL.md`](DATA_MODEL.md) untuk skema & [`AI_PIPELINE.md`](AI_PIPELINE.md) untuk
detail inference.

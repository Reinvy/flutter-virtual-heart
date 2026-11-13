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
  → ObjectBoxService.create()            # openStore + 5 box (pulih dari store korup)
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
│   │   │                             # section_card, confirm_dialog, empty_state, speaker_button
│   │   └── tokens/                   # app_colors (AppPalette/AppPalettes), app_effects (AppBorders),
│   │                                 # app_sizes, app_durations, text_styles
│   ├── errors/app_logger.dart   # satu-satunya logger
│   ├── l10n/app_strings.dart    # AppStrings + IndonesianStrings + EnglishStrings
│   ├── router/app_router.dart   # GoRouter + resolveRedirect (fungsi murni)
│   └── utils/                   # async_fifo_lock, date_formatter, wav_pcm
│   ├── app_settings.dart        # @Entity AppSettings
│   ├── message.dart             # @Entity Message (termasuk isBlocked)
│   ├── memory_fact.dart         # @Entity MemoryFact
│   ├── mood_state.dart          # @Entity MoodState
│   ├── persona_config.dart      # @Entity PersonaConfig
│   ├── objectbox.g.dart         # GENERATED — jangan diedit
│   └── objectbox-model.json     # GENERATED — jangan diedit
├── services/
│   ├── ai/
│   │   ├── model_service.dart        # ModelServiceNotifier (install + inference + stop)
│   │   ├── model_ready_provider.dart # modelReadyProvider (wiring router)
│   │   ├── model_catalog.dart        # 5 model LLM
│   │   ├── speech_model_catalog.dart # 3 TTS + 1 STT
│   │   ├── prompt_builder.dart       # prompt berbatas + selectMemoryFacts
│   │   ├── memory_extractor.dart     # parser "FACT: ..." (tanpa dependensi engine)
│   │   ├── memory_fact_merger.dart   # mergeFacts (fungsi murni)
│   │   └── content_safety.dart       # gate input/output → SafetyRedirect
│   ├── database/
│   │   ├── objectbox_service.dart    # open + pemulihan store korup
│   │   └── objectbox_provider.dart   # objectBoxServiceProvider
│   ├── settings/settings_service.dart # appSettingsProvider + reset flows
│   ├── mood_service.dart             # MoodService (transisi mood)
│   ├── mood_store.dart               # kontrak Box<MoodState>
│   ├── notification_service.dart     # plugin + zona waktu + tap stream
│   ├── notification_time.dart        # nextInstanceOf (fungsi murni)
│   ├── stt_service.dart              # backend 'gemma' | 'system'
│   └── tts_service.dart              # backend 'gemma' | 'system'
└── features/
    ├── hub/            # companion_hub_screen (beranda pendamping & starter)
    ├── onboarding/     # splash, age_gate, onboarding
    ├── persona/        # setup, edit sheet, profile sheet, avatar_catalog, persona_options
    ├── model/          # model_download_screen, model_error_text
    ├── chat/           # chat_screen, chat_controller, mood_provider, widgets/
    ├── memory/         # memory_screen, memory_controller
    ├── settings/       # settings_screen, privacy_screen + widgets/ (section, row,
    │                   # permission_row, appearance, language, model, voice,
    │                   # notifications, data_privacy, persona)
    └── notifications/  # app_lifecycle_observer, notification_controller
```

## 3. Provider (18)

| Provider | Tipe | State | File |
| --- | --- | --- | --- |
| `objectBoxServiceProvider` | `Provider` (di-override di `main`) | `ObjectBoxService` | `services/database/objectbox_provider.dart` |
| `appSettingsProvider` | `NotifierProvider` | `AppSettings` | `services/settings/settings_service.dart` |
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
      ├─ PromptBuilder.buildSystemPrompt(persona, mood, ≤12 fakta, summary≤500, language)
      ├─ PromptBuilder.buildFullPrompt(system, history tanpa isBlocked, text)  # ≤6000 char
      ├─ ModelServiceNotifier.generateResponseStream(fullPrompt, isCancelled:)
      │     ├─ antrean inferensi (chat/memori/ringkasan tidak tumpang tindih)
      │     └─ holdback 64 char: output terlarang tidak pernah terlihat
      ├─ ContentSafety.validateOutput → finalContent (deflection bila perlu)
      ├─ MoodService.updateMoodFromConversation(user, finalContent) → moodProvider.refresh
      ├─ persist Message(assistant, mood: <mood baru>) → state.messages
      ├─ tandai lastReferencedAt HANYA fakta yang dipakai (setelah sukses)
      └─ _enqueuePostProcess (serial):
            ├─ MemoryExtractor.extractFacts → mergeFacts (pure) → put/remove + invalidate
            └─ bila ≥30 pesan baru: summarize → conversationSummary + summaryMessageCount
```

Kegagalan generasi tidak lagi hilang diam-diam: `ChatState.error` membawa `ChatErrorKind`
(`modelUnavailable`, `contextLimit`, `generationFailed`, `interrupted`) yang dipetakan ke
`AppStrings` oleh `ChatScreen`, dengan aksi Coba Lagi/Dismiss. `cancelGeneration()` menandai
pembatalan, memanggil `InferenceChat.stopGeneration()`, lalu menunggu generasi + antrean
post-process selesai — dipakai tombol stop dan sebelum aksi destruktif.

`ModelServiceNotifier` membuat satu `InferenceChat` per permintaan (`openChat`) dan menutupnya
di `finally`, sehingga tidak ada state percakapan yang bocor antar-request. `randomSeed`
diacak per permintaan dan `maxOutputTokens` dibatasi 512 agar jawaban tidak berjalan tanpa batas.

## 6. Service & lifetime

| Service | Lifetime | Catatan |
| --- | --- | --- |
| `ObjectBoxService` | singleton proses | `close()` tidak dipanggil (proses = lifetime app) |
| `ModelServiceNotifier` | provider | memegang `InferenceModel` aktif, `InferenceChat` aktif, `CancelToken` download; FIFO `AsyncFifoLock` + serialisasi `_engineTransition` saat switch/dispose |
| `SttService` | singleton (`factory`) | `AudioRecorder` + `SpeechToText` hidup sepanjang proses |
| `TtsService` | singleton (`factory`) | `FlutterTts` + `FlutterPcmSound` dilepas di `stop()` |
| `NotificationService` | singleton (`factory`) | plugin, zona waktu, `StreamController` broadcast tap |
| `AppLogger` | static | hanya mencetak di debug build |

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

# DATA_MODEL — Skema ObjectBox

ObjectBox **5.3.2**, model version **5** (`lib/objectbox-model.json`, schema diperluas tanpa ganti versi). Binding di
`lib/objectbox.g.dart` **generated** — jangan diedit manual (`make gen-check` memastikan tidak
ada drift).

Regenerasi setelah mengubah entity:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

`build_runner` dipin `2.15.1` dan `objectbox_generator` dipin `5.3.2` (lihat
[`DEPENDENCIES.md`](DEPENDENCIES.md)).

## 1. Entity

### `AppSettings` (24 field)

| Field | Tipe | Default | Catatan |
| --- | --- | --- | --- |
| `id` | int | 0 | `@Id` |
| `ttsEnabled` | bool | `false` | FR-07 |
| `ttsAutoPlay` | bool | `false` | auto-play jawaban AI |
| `ttsBackend` | String | `'system'` | `'system'` / `'gemma'` / `'elevenlabs'` / `'openai'` / `'google'` |
| `sttBackend` | String | `'system'` | independen dari `ttsBackend` (nilai yang sama) |
| `ttsModel` | String | `'inflect'` | `inflect`/`matcha`/`qwen3` (untuk backend `'gemma'`) |
| `sttModel` | String | `'moonshine'` | (untuk backend `'gemma'`) |
| `notificationMorningEnabled` | bool | `false` | FR-15 |
| `notificationMorningTime` | String | `'08:00'` | `HH:mm` |
| `notificationCheckinEnabled` | bool | `false` | FR-16 |
| `notificationCheckinHours` | int | `6` | 1/3/6/12 (dipilih di Settings) |
| `modelVariant` | String | `''` | **nama file** model lokal; kosong = belum dipilih |
| `modelSource` | String | `''` | `''`/`network`/`file` |
| `modelUrl` | String | `''` | URL asal (kosong untuk upload file) |
| `aiModeIndex` | int | `0` | backing field `AiMode {local, cloud}` |
| `activeCloudProfileId` | int | `0` | ID `AiProviderProfile` aktif saat `aiMode == AiMode.cloud` |
| `isAgeVerified` | bool | `false` | FR-01 |
| `isOnboardingDone` | bool | `false` | FR-02 |
| `isPersonaSetup` | bool | `false` | FR-03 |
| `conversationSummary` | String | `''` | FR-13, dipotong 600 karakter |
| `summaryMessageCount` | int | `0` | jumlah pesan saat ringkasan terakhir dibuat |
| `themeIndex` | int | `0` | backing field `AppThemeSetting {light, dark, system}` |
| `themeStyleIndex` | int | `0` | backing field `AppThemeStyle {editorial, romantic, classic, botanical}` |
| `languageIndex` | int | `0` | backing field `AppLanguage {indonesian, english, mixed}` |

`theme`/`themeStyle`/`language`/`aiMode` diekspos sebagai getter/setter di atas backing index-nya
(enum tidak disimpan langsung — ObjectBox melewati properti bertipe enum). Getter meng-clamp
index pada seluruh entity (`AppSettings`, `Message`, `PersonaConfig`, `MoodState`, `MemoryFact`,
`AiProviderProfile`) sehingga baris rusak tidak melempar `RangeError`, dan `normalized()`
memperbaiki nilai string/int yang tidak valid saat boot.

### `AiProviderProfile` (BYOK Cloud LLM)

Menyimpan profil provider Cloud BYOK (non-rahasia; API key **tidak** disimpan di ObjectBox):

- **Identitas & koneksi**: `id`, `profileKey` (kunci stabil untuk `SecretStore`), `name`,
  `providerTypeIndex` (`LlmProviderType {google, anthropic, openai}`), `baseUrl`, `modelId`,
  `customHeadersJson`, `createdAt`, `updatedAt`.
- **Parameter generasi**: `temperature` (`double?`, 0.0–2.0; maks 1.0 di Anthropic), `topP`
  (`double?`), `topK` (`int?`), `maxOutputTokens` (`int`, 256–32768, default 2048),
  `presencePenalty` (`double?`, -2.0–2.0), `frequencyPenalty` (`double?`, -2.0–2.0),
  `stopSequencesCsv`, `seed` (`int?`), `reasoningEffort` (`''`/`'none'`/`'minimal'`/`'low'`/
  `'medium'`/`'high'`/`'max'`/`'adaptive'`), `thinkingBudgetTokens` (`int?`),
  `geminiSafetyLevel` (`'default'`/`'block_only_high'`/`'block_none'`),
  `stripStreamOptions` (`bool`), `timeoutSeconds` (`int`, 15–300, default 60).
- **Kebebasan konteks & background**: `maxHistoryMessages` (10–200, default 40),
  `maxMemoryFacts` (5–100, default 30), `maxInputChars` (2000–64000, default 12000),
  `maxPromptChars` (6000–256000, default 64000), `enforceShortReply` (`bool`, default `false`),
  `customSystemPrompt` (`String`), `enableBackgroundTasks` (`bool`, default `true`),
  `backgroundModelId` (`String`).

### `CloudSpeechConfig` (single-row)

Menyimpan konfigurasi non-rahasia untuk Cloud TTS & Cloud STT:

- **ElevenLabs**: `elevenLabsBaseUrl`, `elevenLabsVoiceId`, `elevenLabsVoiceName`,
  `elevenLabsTtsModel` (`eleven_multilingual_v2`), `elevenLabsStability`,
  `elevenLabsSimilarityBoost`, `elevenLabsStyle`, `elevenLabsSpeed`,
  `elevenLabsUseSpeakerBoost`, `elevenLabsOutputFormat` (`mp3_44100_128`),
  `elevenLabsSttModel` (`scribe_v2`), `elevenLabsSttTagAudioEvents`, `elevenLabsSttDiarize`.
- **OpenAI & OpenAI-compatible (termasuk Groq Whisper)**: `openaiTtsReuseLlmKey`,
  `openaiTtsBaseUrl`, `openaiTtsModel` (`gpt-4o-mini-tts`), `openaiTtsVoice` (`coral`),
  `openaiTtsSpeed`, `openaiTtsInstructions`, `openaiTtsFormat` (`mp3`), `openaiSttReuseLlmKey`,
  `openaiSttBaseUrl`, `openaiSttModel` (`gpt-4o-mini-transcribe`), `openaiSttPrompt`,
  `openaiSttTemperature`.
- **Google Gemini Speech**: `googleSpeechReuseLlmKey`, `googleSpeechBaseUrl`,
  `googleTtsModel` (`gemini-2.5-flash-preview-tts`), `googleTtsVoiceName` (`Aoede`),
  `googleTtsStylePrompt`, `googleSttModel` (`gemini-2.5-flash`).
- **Umum**: `timeoutSeconds` (10–120, default 45).

### Penyimpanan API Key (`SecretStore`)

Seluruh API key BYOK disimpan terenkripsi lewat `flutter_secure_storage`
(`lib/services/ai/secret_store.dart`), bukan di ObjectBox maupun `SharedPreferences`:

- LLM per profil: `byok_llm_<profileKey>`
- Speech: `byok_speech_elevenlabs`, `byok_speech_openai_tts`, `byok_speech_openai_stt`,
  `byok_speech_google`
### `PersonaConfig`

`id`, `name`, `nicknameForUser`, `avatarId`, `createdAt` (`PropertyType.date`),
`genderIndex` (`PersonaGender {girlfriend, boyfriend}`), `personalityPresetIndex`
(`PersonalityPreset {gentle, cheerful, mature, mysterious}`), `hobbies` (`List<String>`).
Tidak ada `voiceId` — pemilihan suara bersifat global (`AppSettings.tts*`), bukan per-persona.

### `Message`

`id`, `content`, `isVoice` (bool), `mood` (String?, nama `MoodType` saat jawaban dibuat),
`timestamp` (`date`), `roleIndex` (`MessageRole {user, assistant}`), `isBlocked` (bool, default
`false`). Pesan `isBlocked` tetap tampil di UI tetapi tidak pernah masuk prompt, ringkasan,
ekstraksi memori, maupun skoring mood.

### `MemoryFact`

`id`, `key`, `value`, `sourceSnippet` (String?, potongan pesan user pemicu),
`createdAt`, `lastReferencedAt` (`date`, diperbarui setiap fakta dipakai di prompt),
`categoryIndex` (`MemoryCategory {personal, event, preference, date}`).

### `MoodState`

`id`, `intensity` (double 0–1), `lastUpdatedAt`, `lastInteractionAt` (`date`),
`currentIndex` (`MoodType {happy, longing, playful, sad, excited}`).

## 2. Box & konvensi

| Box | Entity |
| --- | --- |
| `appSettingsBox` | `AppSettings` |
| `personaBox` | `PersonaConfig` |
| `messageBox` | `Message` |
| `memoryFactBox` | `MemoryFact` |
| `moodStateBox` | `MoodState` |
| `aiProviderProfileBox` | `AiProviderProfile` |
| `cloudSpeechConfigBox` | `CloudSpeechConfig` |

- **Single-row convention**: `AppSettings`, `PersonaConfig`, `MoodState`, `CloudSpeechConfig`
  dibaca dengan memilih baris **id terkecil** lalu menghapus duplikat (`getOrCreateSettings`,
  `getOrCreateCloudSpeechConfig`, `PersonaNotifier.build`, `MoodService.getCurrentMood`). Tidak
  ada `@Unique`, jadi kanonikalisasi dilakukan di kode.
- Tidak ada relasi ObjectBox; seluruh asosiasi dilakukan lewat query/box langsung.
- Store dibuka di `getApplicationDocumentsDirectory()/virtualheartdb`.

## 3. Flow hapus & reset

| Aksi | Yang dihapus | Yang dipertahankan |
| --- | --- | --- |
| Hapus semua percakapan (`AppSettingsNotifier.deleteAllConversations`) | semua `Message` + `conversationSummary` + `summaryMessageCount=0` (satu transaksi) | persona, memori, mood, profil cloud, settings lain |
| Reset persona (`AppSettingsNotifier.resetPersonaData`) | `personaBox`, `memoryFactBox`, `moodStateBox`, `messageBox`; `isPersonaSetup=false`; `conversationSummary=''`; `summaryMessageCount=0` (satu transaksi) | model + profil cloud + settings lain (tema/bahasa/suara/notifikasi) |
| Reset semua data (`AppSettingsNotifier.resetAllData`) | persona, memori, mood, pesan, settings, `aiProviderProfileBox`, `cloudSpeechConfigBox`, seluruh API key BYOK di `SecretStore`, token `hf_token`, file `virtualheart_*.txt` | **file model lokal** + identitas model (`modelVariant`/`modelSource`/`modelUrl` disalin ke settings baru, `aiMode=local`) |

`resetAllData` mempertahankan identitas model lokal agar model 1–2 GB yang sudah diunduh tidak perlu
diunduh ulang, sekaligus menghapus seluruh profil Cloud BYOK dan seluruh API key terenkripsi. Aksi
destruktif menunggu `ChatNotifier.cancelGeneration()` (generasi + post-process) dan
`ModelServiceNotifier.cancelDownload()` selesai, lalu meng-invalidate provider terkait di UI
(`chatProvider`, `pendingChatDraftProvider`, `memoryFactsProvider`, `personaProvider`,
`moodProvider`, `aiProviderProfilesProvider`, `cloudSpeechConfigProvider`, `modelServiceProvider`,
`modelReadyProvider`, `notificationProvider`).

## 4. Pemulihan store korup

Bila `openStore` gagal (file store korup/tidak kompatibel), `ObjectBoxService.create()`:
1. mencatat kegagalan (`AppLogger.warn`),
2. mengganti nama direktori `virtualheartdb` menjadi `virtualheartdb.corrupt-<timestamp>`,
3. mencoba `openStore` sekali lagi.

Bila percobaan kedua gagal, error dilempar dan `main()` menampilkan `BootstrapErrorApp`. Data
lama tidak dihapus — hanya dipindahkan, sehingga masih bisa diperiksa manual.

## 5. Test persistensi

`test/core/objectbox_settings_test.dart` menulis **setiap** field `AppSettings` non-default
(tema, bahasa, suara, notifikasi + interval check-in, model + sumber/URL, flag, ringkasan +
`summaryMessageCount`), menutup store, membuka ulang, lalu memeriksa semuanya kembali. File yang
sama juga memeriksa `normalized()` untuk baris lama yang rusak.

Test membutuhkan `libobjectbox.so`/`.dylib` di host; bila tidak tersedia test **di-skip** di
mesin lokal dan **gagal** di CI (`CI=true`), sehingga regresi tidak bisa lolos diam-diam. Cara
menyediakan library: lihat [`TESTING.md`](TESTING.md).

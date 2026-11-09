# DATA_MODEL — Skema ObjectBox

ObjectBox **5.3.2**, model version **5** (`lib/objectbox-model.json`). Binding di
`lib/objectbox.g.dart` **generated** — jangan diedit manual.

Regenerasi setelah mengubah entity:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

`build_runner` dipin `2.15.1` dan `objectbox_generator` dipin `5.3.2` (lihat
[`DEPENDENCIES.md`](DEPENDENCIES.md)).

## 1. Entity

### `AppSettings` (19 field)

| Field | Tipe | Default | Catatan |
| --- | --- | --- | --- |
| `id` | int | 0 | `@Id` |
| `ttsEnabled` | bool | `false` | FR-07 |
| `ttsAutoPlay` | bool | `false` | auto-play jawaban AI |
| `ttsBackend` | String | `'gemma'` | `'gemma'` = on-device, `'system'` |
| `sttBackend` | String | `'gemma'` | idem |
| `ttsModel` | String | `'inflect'` | `inflect`/`matcha`/`qwen3` |
| `sttModel` | String | `'moonshine'` | |
| `notificationMorningEnabled` | bool | `false` | FR-15 |
| `notificationMorningTime` | String | `'08:00'` | `HH:mm` |
| `notificationCheckinEnabled` | bool | `false` | FR-16 |
| `modelVariant` | String | `'qwen2.5-1.5b'` | setelah install berisi **nama file** model |
| `modelSource` | String | `''` | `''`/`network`/`file` |
| `modelUrl` | String | `''` | URL asal (kosong untuk upload file) |
| `isAgeVerified` | bool | `false` | FR-01 |
| `isOnboardingDone` | bool | `false` | FR-02 |
| `isPersonaSetup` | bool | `false` | FR-03 |
| `conversationSummary` | String | `''` | FR-13 |
| `themeIndex` | int | `0` | backing field `AppThemeSetting {light, dark, system}` |
| `languageIndex` | int | `0` | backing field `AppLanguage {indonesian, english, mixed}` |

`theme`/`language` diekspos sebagai getter/setter di atas `themeIndex`/`languageIndex`
(enum tidak disimpan langsung — ObjectBox melewati properti bertipe enum).

### `PersonaConfig`

`id`, `name`, `nicknameForUser`, `avatarId`, `createdAt` (`PropertyType.date`),
`genderIndex` (`PersonaGender {girlfriend, boyfriend}`), `personalityPresetIndex`
(`PersonalityPreset {gentle, cheerful, mature, mysterious}`), `hobbies` (`List<String>`).
Tidak ada `voiceId` — pemilihan suara bersifat global (`AppSettings.tts*`), bukan per-persona.

### `Message`

`id`, `content`, `isVoice` (bool), `mood` (String?, nama `MoodType` saat jawaban dibuat),
`timestamp` (`date`), `roleIndex` (`MessageRole {user, assistant}`).

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

- **Single-row convention**: `AppSettings`, `PersonaConfig`, `MoodState` dibaca via
  `box.getAll().first`; `ObjectBoxService.getOrCreateSettings()` membuat baris default bila
  kosong. Tidak ada unique constraint/`@Unique` — lihat [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).
- Tidak ada relasi ObjectBox; seluruh asosiasi dilakukan lewat query/box langsung.
- Store dibuka di `getApplicationDocumentsDirectory()/virtualheartdb`.

## 3. Flow hapus & reset

| Aksi | Yang dihapus | Yang dipertahankan |
| --- | --- | --- |
| Hapus semua percakapan (`AppSettingsNotifier.deleteAllConversations`) | semua `Message` + `conversationSummary` | persona, memori, mood, settings lain |
| Reset persona (`PersonaSection`) | `personaBox`, `memoryFactBox`, `moodStateBox`; `isPersonaSetup=false`; `conversationSummary=''` | percakapan, settings lain |
| Reset semua data (`AppSettingsNotifier.resetAllData`) | persona, memori, mood, pesan, settings | **file model** + identitas model (`modelVariant`/`modelSource`/`modelUrl` disalin ke settings baru) |

`resetAllData` mempertahankan identitas model agar model 1–2 GB yang sudah diunduh tidak perlu
diunduh ulang. Semua aksi di atas juga meng-invalidate provider terkait di UI
(`chatProvider`, `memoryFactsProvider`, `personaProvider`, `moodProvider`,
`modelServiceProvider`, `modelReadyProvider`).

## 4. Test persistensi

`test/core/objectbox_settings_test.dart` menulis `AppSettings` dengan nilai non-default,
menutup store, membuka ulang, lalu memeriksa 7 field (`ttsBackend`, `sttBackend`, `ttsModel`,
`sttModel`, `modelSource`, `modelUrl`, `modelVariant`). Test ini menjaga regresi binding stale
yang dulu membuat 6 field tidak pernah tersimpan.

Test membutuhkan `libobjectbox.so`/`.dylib` di host; bila tidak tersedia test **di-skip**
(bukan dihapus). Cara menyediakannya: lihat [`TESTING.md`](TESTING.md).

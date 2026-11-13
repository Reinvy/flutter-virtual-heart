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

### `AppSettings` (22 field)

| Field | Tipe | Default | Catatan |
| --- | --- | --- | --- |
| `id` | int | 0 | `@Id` |
| `ttsEnabled` | bool | `false` | FR-07 |
| `ttsAutoPlay` | bool | `false` | auto-play jawaban AI |
| `ttsBackend` | String | `'system'` | `'gemma'` = on-device, `'system'` |
| `sttBackend` | String | `'system'` | idem |
| `ttsModel` | String | `'inflect'` | `inflect`/`matcha`/`qwen3` |
| `sttModel` | String | `'moonshine'` | |
| `notificationMorningEnabled` | bool | `false` | FR-15 |
| `notificationMorningTime` | String | `'08:00'` | `HH:mm` |
| `notificationCheckinEnabled` | bool | `false` | FR-16 |
| `notificationCheckinHours` | int | `6` | 1/3/6/12 (dipilih di Settings) |
| `modelVariant` | String | `''` | **nama file** model; kosong = belum dipilih |
| `modelSource` | String | `''` | `''`/`network`/`file` |
| `modelUrl` | String | `''` | URL asal (kosong untuk upload file) |
| `isAgeVerified` | bool | `false` | FR-01 |
| `isOnboardingDone` | bool | `false` | FR-02 |
| `isPersonaSetup` | bool | `false` | FR-03 |
| `conversationSummary` | String | `''` | FR-13, dipotong 600 karakter |
| `summaryMessageCount` | int | `0` | jumlah pesan saat ringkasan terakhir dibuat |
| `themeIndex` | int | `0` | backing field `AppThemeSetting {light, dark, system}` |
| `themeStyleIndex` | int | `0` | backing field `AppThemeStyle {editorial, romantic, classic, botanical}` |
| `languageIndex` | int | `0` | backing field `AppLanguage {indonesian, english, mixed}` |

`theme`/`themeStyle`/`language` diekspos sebagai getter/setter di atas backing index-nya
(enum tidak disimpan langsung — ObjectBox melewati properti bertipe enum). Getter meng-clamp
index sehingga baris rusak tidak melempar `RangeError`, dan `normalized()` memperbaiki nilai
string/int yang tidak valid saat boot (backend suara, model, jam pagi, interval check-in).
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

- **Single-row convention**: `AppSettings`, `PersonaConfig`, `MoodState` dibaca dengan memilih
  baris **id terkecil** lalu menghapus duplikat (`getOrCreateSettings`, `PersonaNotifier.build`,
  `MoodService.getCurrentMood`). Tidak ada `@Unique`, jadi kanonikalisasi dilakukan di kode.
- Tidak ada relasi ObjectBox; seluruh asosiasi dilakukan lewat query/box langsung.
- Store dibuka di `getApplicationDocumentsDirectory()/virtualheartdb`.

## 3. Flow hapus & reset

| Aksi | Yang dihapus | Yang dipertahankan |
| --- | --- | --- |
| Hapus semua percakapan (`AppSettingsNotifier.deleteAllConversations`) | semua `Message` + `conversationSummary` + `summaryMessageCount=0` (satu transaksi) | persona, memori, mood, settings lain |
| Reset persona (`AppSettingsNotifier.resetPersonaData`) | `personaBox`, `memoryFactBox`, `moodStateBox`, `messageBox`; `isPersonaSetup=false`; `conversationSummary=''`; `summaryMessageCount=0` (satu transaksi) | model + settings lain (tema/bahasa/suara/notifikasi) |
| Reset semua data (`AppSettingsNotifier.resetAllData`) | persona, memori, mood, pesan, settings, token `hf_token`, file `virtualheart_*.txt` (satu transaksi untuk box) | **file model** + identitas model (`modelVariant`/`modelSource`/`modelUrl` disalin ke settings baru) |

`resetAllData` mempertahankan identitas model agar model 1–2 GB yang sudah diunduh tidak perlu
diunduh ulang. Aksi destruktif menunggu `ChatNotifier.cancelGeneration()` (generasi +
post-process) dan `ModelServiceNotifier.cancelDownload()` selesai, lalu meng-invalidate provider
terkait di UI (`chatProvider`, `memoryFactsProvider`, `personaProvider`, `moodProvider`,
`modelServiceProvider`, `modelReadyProvider`).

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

# FEATURES — Spesifikasi & Status

Status dokumen ini adalah **kondisi kode saat ini**, bukan rencana.

| Status | Arti |
| --- | --- |
| `Implemented` | seluruh acceptance criteria terpenuhi |
| `Partial` | berfungsi, sebagian kriteria belum (lihat `KNOWN_ISSUES`) |
| `Backlog` | belum ada di aplikasi (hanya rencana) |

Format rujukan: path relatif terhadap root repo. ID FR unik dan dipakai lintas dokumen.

---

## Alur Awal (Setup Flow)

### FR-01 — Age Gate (13+) — `Implemented`

- Gerbang usia wajib sebelum fitur lain; `AppSettings.isAgeVerified` disimpan di ObjectBox.
- Menolak → dialog tidak bisa melanjutkan + tutup aplikasi (`SystemNavigator.pop`).
- Teks ID/EN lewat `AppStrings`; locale Material mengikuti bahasa app.
- Edge case: aplikasi dimatikan sebelum konfirmasi → gerbang muncul lagi.
- Ref: `lib/features/onboarding/age_gate_screen.dart`, `lib/app.dart`, `lib/core/router/app_router.dart`.

### FR-02 — Onboarding — `Implemented`

- 3 halaman, bisa dilewati; flag `isOnboardingDone`.
- Edge case: sudah onboarding tapi belum persona → guard mengarahkan ke `/persona-setup`.
- Ref: `lib/features/onboarding/onboarding_screen.dart`.

### FR-03 — Persona Setup & Edit — `Partial`

- Buat/ubah persona: gender (girlfriend/boyfriend), nama (2–32 karakter), panggilan untuk user,
  preset kepribadian (gentle/cheerful/mature/mysterious), hobi, 6 avatar per gender.
- Edit dari profile sheet chat **dan** dari Settings membuka form yang sama; tidak ada route
  edit terpisah.
- `PersonaConfig` tidak menyimpan `voiceId` (lihat FR-07).
- ⚠️ `Partial`: pemilihan suara tidak per-persona, melainkan global.
- Edit memakai `Form` dengan validator yang sama seperti setup (nama 2–32, panggilan wajib),
  termasuk pemilihan hobi; keyboard tidak menutupi tombol simpan, dan menutup sheet dengan
  perubahan belum disimpan meminta konfirmasi "Buang perubahan?".
- Edge case: nama kosong/terlalu pendek → error inline; edit tanpa mengubah field tetap menyimpan
  `id` yang sama (tidak membuat duplikat).
- Ref: `lib/features/persona/`, `lib/models/persona_config.dart`.

### FR-04 — Model Install & Katalog — `Implemented`

- 5 model (Qwen 2.5 1.5B default, Qwen 2.5 0.5B, SmolLM 135M, DeepSeek R1 1.5B, Gemma 3 1B)
  diunduh dari HuggingFace dengan progress dan tombol batal, **atau** file `.litertlm`/`.task`
  di-upload dari perangkat.
- Token HuggingFace opsional (model gated) disimpan di `SharedPreferences`.
- Setelah sukses: `modelVariant` = nama file, `modelSource` = `network`/`file`, `modelUrl` = URL.
- Restart: model terpasang dikenali lewat `isModelInstalled(nama file)`. **Tidak ada**
  auto-download saat pertama buka — pengguna memilih model (atau satu-satunya model terpasang
  dipakai otomatis).
- Ganti model kapan saja lewat Settings → Model AI atau `/model-download` (ada tombol kembali,
  badge "Aktif", label tombol Pakai/Aktif, dan tombol Coba Lagi saat gagal).
- Error instalasi dipetakan ke kind (`network`/`auth`/`notFound`/`rateLimited`/`storage`/
  `invalidFile`/`engine`/`unknown`) dan ditampilkan lewat `AppStrings`; batal unduhan memulihkan
  status sebelumnya tanpa banner error.
- ⚠️ Belum ada preflight ruang penyimpanan/peringatan RAM rendah (KI-09).
- Edge case: file kustom tetap dikenali (identitas = nama file); ekstensi lain, file kosong, atau
  pemilihan jenis model yang dibatalkan tidak memulai instalasi.
- Ref: `lib/features/model/model_download_screen.dart`, `lib/services/ai/model_service.dart`,
  `lib/services/ai/model_catalog.dart`.

---

## Chat & Suara

### FR-05 — Chat Streaming — `Implemented`

- Input maksimum 2000 karakter (counter muncul di atas 1800); pesan user dipersist setelah gate
  keamanan dan langsung tampil.
- Token AI muncul bertahap (bubble streaming), `TypingIndicator` sebelum token pertama.
- Tombol stop menggantikan tombol kirim selama generasi; jawaban parsial disimpan dan banner
  "Jawaban terhenti" muncul. Kegagalan generasi menampilkan error terlokalisasi + Coba Lagi.
- Riwayat lengkap dipersist di ObjectBox, diurutkan `(timestamp, id)`, dimuat ulang saat app
  dibuka, dan langsung menggulir ke pesan terbaru; auto-scroll hanya saat pengguna berada di
  bawah. Teks bubble bisa diseleksi.
- Markdown dari model tidak pernah memuat gambar jaringan (privacy).
- Ref: `lib/features/chat/chat_screen.dart`, `lib/features/chat/chat_controller.dart`,
  `lib/services/ai/model_service.dart`.

### FR-06 — Voice Input (STT) — `Partial`

- Dua backend: on-device (Moonshine, rekam WAV 16 kHz mono) dan sistem (`speech_to_text`).
- Transkrip masuk ke input untuk diedit, lalu terkirim dengan `Message.isVoice = true`.
- Izin mikrofon diminta saat dipakai; penolakan → SnackBar `chatMicPermission` dengan aksi
  "Buka Pengaturan". Transkrip disisipkan di posisi kursor, bukan menimpa teks yang ada.
- TTS dihentikan sebelum mikrofon aktif; sesi ganda ditolak (`busy`).
- ⚠️ `Partial`: tidak ada visualisasi waveform/progress transkripsi.
- Edge case: rekaman tanpa akhir → `stopListening` mengembalikan string kosong (tanpa error ke
  UI); WAV tanpa chunk `data` ditolak parser (`FormatException`) dan sesi dianggap gagal.
- Ref: `lib/services/stt_service.dart`, `lib/core/utils/wav_pcm.dart`,
  `lib/features/chat/widgets/input_bar.dart`.

### FR-07 — Voice Output (TTS) — `Partial`

- Dua backend: on-device (Inflect default, Matcha, Qwen3) dan suara sistem (`flutter_tts`).
- Play/stop per bubble AI (tombol disembunyikan saat TTS mati); auto-play opsional setelah
  jawaban selesai, hanya jika layar chat sedang aktif.
- Bahasa TTS mengikuti `AppSettings.language` (`id-ID`/`en-US`) dan diteruskan ke engine.
- Ganti model benar-benar memasang/mengaktifkan model yang dipilih; status "Terpasang" hanya
  muncul bila model benar-benar aktif. Utterance baru membatalkan yang lama.
- ⚠️ `Partial`: selesai playback diperkirakan dari durasi PCM (bukan callback plugin).
- Edge case: model belum tersedia → SnackBar `chatTtsUnavailable`, chat tetap jalan; meninggalkan
  layar chat menghentikan audio.
- Ref: `lib/services/tts_service.dart`, `lib/features/chat/widgets/chat_bubble.dart`.

### FR-08 — Typing Indicator — `Implemented`
- Indikator animasi di editorial thread AI saat `ChatState.isTyping` dan belum ada token.
- Ref: `lib/features/chat/widgets/typing_indicator.dart`.

### FR-09 — Dynamic Mood Engine — `Implemented`

- 5 mood (happy, longing, playful, sad, excited) dengan intensitas 0–1.
- Diperbarui dari sentimen jawaban AI, turun ke `longing` setelah 6/12 jam idle.
- Mood diinjeksikan ke system prompt dan ditampilkan di AppBar + profile sheet.
- Ref: `lib/services/mood_service.dart`, `lib/features/chat/mood_provider.dart`,
  `lib/features/chat/widgets/mood_indicator.dart`.

### FR-10 — Persona Profile Sheet & Companion Hub — `Implemented`

- Bottom sheet dari AppBar chat maupun Companion Hub (`/hub`): avatar besar, nama, gender,
  panggilan, kartu mood (emoji + intensitas), chip hobi, kartu kepribadian, tombol Edit.
- `CompanionHubScreen` (`/hub`) menjadi tab beranda default pasca-setup dengan status pendamping,
  3 conversation starters (mengisi `pendingChatDraftProvider` lalu membuka `/chat`), serta snapshot
  Memori dan Mesin Lokal.
- Edit membuka `PersonaEditSheet` (bukan route), perubahan langsung terlihat.
- Ref: `lib/features/hub/companion_hub_screen.dart`,
  `lib/features/persona/persona_profile_sheet.dart`,
  `lib/features/persona/persona_edit_sheet.dart`.

---

## Memori & Konteks

### FR-11 — Memory Extraction — `Implemented`

- Setiap jawaban AI memicu ekstraksi fakta `FACT: category | key | value` (best-effort).
- Fakta digabung berdasarkan `key` (case-insensitive): nilai/kategori/sumber diperbarui, bukan
  duplikat. `sourceSnippet` menyimpan pesan user pemicu.
- `lastReferencedAt` hanya diperbarui untuk fakta yang dipakai menyusun prompt, setelah generasi
  sukses. Maksimum 12 fakta per prompt, 50 fakta tersimpan (tertua dihapus), panjang field dibatasi.
- Kategori: personal, event, preference, date.
- Edge case: model mengembalikan format salah → tidak ada fakta baru, chat tidak gagal.
- Ref: `lib/services/ai/memory_extractor.dart`, `lib/features/chat/chat_controller.dart`.

### FR-12 — Memory Screen — `Implemented`

- Daftar fakta per kategori, pencarian key/value, hapus satu fakta, reset semua fakta.
- Ref: `lib/features/memory/memory_screen.dart`, `lib/features/memory/memory_controller.dart`.

### FR-13 — Conversation Summarization — `Implemented`

- Saat pesan tak-terblokir bertambah ≥ 30 sejak `summaryMessageCount`, ringkasan 3–5 kalimat
  dibuat (maks. 60 pesan terakhir, prompt berbatas karakter) dan disimpan bersama
  `summaryMessageCount` baru.
- Ringkasan (maks. 500 karakter) diinjeksikan ke system prompt sebagai `[CONTEXT SUMMARY]`.
- Hapus semua percakapan, reset persona, dan reset total menghapus ringkasan + counternya.
- Ref: `lib/services/ai/prompt_builder.dart`, `lib/services/settings/settings_service.dart`.

### FR-14 — Content Safety — `Implemented`

- Gate input berjalan **sebelum** pesan dipersist; gate output berjalan selama streaming
  (holdback 64 karakter) dan sekali lagi di akhir. Kategori: explicit sexual, self-harm,
  professional advice, hate speech, violence instruction, persona break.
- Pesan terblokir ditandai `Message.isBlocked` dan tidak pernah masuk prompt, ringkasan, memori,
  atau mood. Konten terblokir diganti deflection `AppStrings` yang terlokalisasi; tidak ada pesan
  error teknis ke UI.
- Ref: `lib/services/ai/content_safety.dart`, `test/core/content_safety_test.dart`.

---

## Notifikasi

### FR-15 — Morning Message — `Implemented`

- Notifikasi harian pada jam pilihan (`AppSettings.notificationMorningTime`), teks acak,
  dijadwalkan ulang saat settings berubah.
- Tap notifikasi membuka chat (bila seluruh gate selesai & model siap).
- Edge case: izin notifikasi ditolak → jadwal tidak dibuat, UI menampilkan status izin.
- Ref: `lib/services/notification_service.dart`,
  `lib/features/notifications/notification_controller.dart`.

### FR-16 — Check-in Notification — `Implemented`

- Saat app masuk background (`paused`) dan fitur aktif, check-in dijadwalkan sesuai
  `AppSettings.notificationCheckinHours` (pilihan 1/3/6/12 jam di Settings); dibatalkan saat app
  kembali (`resumed`).
- Penjadwalan hanya terjadi bila izin notifikasi ada; body memakai `AppStrings.checkinMessages`.
- Ref: `lib/features/notifications/app_lifecycle_observer.dart`,
  `lib/services/notification_service.dart`.

### FR-17 — Special Day Notification — `Backlog`

- API `scheduleSpecialDay`/`cancelSpecialDay` ada (tanggal masa depan saja, slot id), tetapi
  **belum ada UI** yang memanggilnya.
- Ref: `lib/services/notification_service.dart`; status: `KNOWN_ISSUES` KI-06.

---

## Settings & Privasi

### FR-18 — Settings — `Implemented`

- Section: Persona (ringkasan + edit + reset), Tampilan (mode kecerahan light/dark/system +
  4 preset gaya tema Editorial/Romantic/Classic/Botanical), Bahasa (ID/EN/mixed), **Model AI**
  (model aktif + Ganti Model), Suara (TTS on/off, auto-play, backend, model), Notifikasi
  (morning message, jam, check-in + interval, izin), Data & Privasi.
- Izin ditampilkan apa adanya: tile izin tidak memunculkan dialog saat layar dibuka, dan sakelar
  notifikasi menolak aktif tanpa izin OS (SnackBar panduan).
- Section memakai warna `ColorScheme` (kontras AA di light & dark) dan tidak overflow pada 320 dp.
- Ref: `lib/features/settings/`.

### FR-19 — Data & Privasi — `Implemented`

- Hapus semua percakapan (+ ringkasan + counter) dalam satu transaksi → `chatProvider` disegarkan.
- Ekspor riwayat chat ke `.txt` lewat dialog simpan OS (`FilePicker.saveFile`) dengan header
  terlokalisasi; platform tanpa dialog simpan memakai dokumen aplikasi + path lengkap di SnackBar.
- Reset persona: persona, memori, mood, **percakapan**, ringkasan dihapus; kembali ke
  `/persona-setup`.
- Reset semua data: persona, memori, mood, pesan, settings, token HuggingFace, dan file ekspor
  dihapus; notifikasi dibatalkan; kembali ke `/age-gate`. File model + identitasnya dipertahankan.
- Aksi destruktif menunggu generasi/unduhan berhenti dan memakai dialog konfirmasi terlokalisasi.
- Kebijakan privasi bisa dibaca di aplikasi (`/privacy`) dari age gate maupun Settings.
- Ref: `lib/features/settings/widgets/data_privacy_section.dart`,
  `lib/features/settings/widgets/persona_section.dart`,
  `lib/services/settings/settings_service.dart`.

### FR-20 — Bahasa (Indonesia / English / Mixed) — `Implemented`

- `AppSettings.language` mengatur: string UI (`AppStrings`), locale Material
  (`GlobalMaterialLocalizations`), bahasa keluaran AI (instruksi di system prompt), bahasa
  TTS/STT, body notifikasi, deflection safety, error model, header ekspor, dan kebijakan privasi.
- Tag hobi disimpan dalam bahasa Inggris di `PersonaConfig.hobbies`, sedangkan label UI
  dilokalisasi ke ID/EN lewat `AppStrings.personaHobbyLabel`.
- Ref: `lib/core/l10n/app_strings.dart`, `lib/services/ai/prompt_builder.dart`, `lib/app.dart`.

---

## Fitur Peningkatan (Backlog)

| ID | Usulan | Prioritas | Status | Catatan |
| --- | --- | --- | --- | --- |
| FR-21 | Mood history & tren | P2 | Backlog | butuh entity baru |
| FR-22 | Good night / momen harian | P2 | Backlog | memperluas FR-15 |
| FR-23 | Ekspor/cadangan JSON | P2 | Backlog | tetap on-device |
| FR-24 | Ringkasan harian "kenangan bersama" | P2 | Backlog | memanfaatkan FR-13 |
| FR-25 | Multi-persona | P2 | Backlog | perubahan skema besar |
| FR-26 | Paket avatar/suara tambahan | P1 | Backlog | konten lokal, tanpa jaringan |
| FR-27 | Quiet hours notifikasi | P2 | Backlog | melengkapi FR-15/16/17 |

---

## Edge Cases Umum

| Kondisi | Perilaku saat ini |
| --- | --- |
| Model belum siap | banner `chatModelUnavailable` + guard `/model-download` |
| Model gagal dimuat | error kind + tombol Coba Lagi di layar model |
| Izin mikrofon/notifikasi ditolak | fitur terkait nonaktif, SnackBar dengan aksi pengaturan |
| Penyimpanan penuh | belum ada preflight (KI-09) |
| App dibunuh saat generasi | pesan user sudah tersimpan; jawaban parsial tidak |
| Data DB korup | direktori store diganti nama `.corrupt-<ts>` dan store dibuka ulang (KI-14) |
| Bootstrap gagal total | `BootstrapErrorApp` dua bahasa, bukan layar kosong |
| Tidak ada jaringan saat install | error kind network + tombol Coba Lagi |
| Bahasa UI diganti | string, locale Material, TTS/STT, dan instruksi AI ikut berubah |

## Matriks Rujukan

| FR | Fitur UI | Data / layanan |
| --- | --- | --- |
| FR-01 | `features/onboarding/age_gate_screen.dart` | `AppSettings.isAgeVerified` |
| FR-02 | `features/onboarding/onboarding_screen.dart` | `AppSettings.isOnboardingDone` |
| FR-03 | `features/persona/` | `PersonaConfig` |
| FR-04 | `features/model/model_download_screen.dart` | `services/ai/model_service.dart`, `model_catalog.dart` |
| FR-05 | `features/chat/chat_screen.dart` | `Message`, `services/ai/prompt_builder.dart` |
| FR-06 | `features/chat/widgets/input_bar.dart` | `services/stt_service.dart`, `core/utils/wav_pcm.dart` |
| FR-07 | `features/chat/widgets/chat_bubble.dart` | `services/tts_service.dart`, `AppSettings.tts*` |
| FR-08 | `features/chat/widgets/typing_indicator.dart` | `ChatState.isTyping` |
| FR-09 | `features/chat/widgets/mood_indicator.dart` | `MoodState`, `services/mood_service.dart` |
| FR-10 | `features/persona/persona_profile_sheet.dart` | `PersonaConfig`, `MoodState` |
| FR-11 | `features/chat/` (post-process) | `MemoryFact`, `services/ai/memory_extractor.dart` |
| FR-12 | `features/memory/memory_screen.dart` | `MemoryFact` |
| FR-13 | `features/settings/` | `AppSettings.conversationSummary` |
| FR-14 | `features/chat/` (gates) | `services/ai/content_safety.dart` |
| FR-15 | `features/settings/widgets/notifications_section.dart` | `services/notification_service.dart` |
| FR-16 | `features/notifications/app_lifecycle_observer.dart` | `services/notification_service.dart` |
| FR-17 | — (belum ada UI) | `services/notification_service.dart` |
| FR-18 | `features/settings/settings_screen.dart` | `AppSettings` |
| FR-19 | `features/settings/widgets/data_privacy_section.dart`, `features/settings/privacy_screen.dart` | ObjectBox (semua box), `SharedPreferences` |
| FR-20 | `features/settings/widgets/language_section.dart` | `core/l10n/app_strings.dart`, `AppLanguage` |

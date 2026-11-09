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
- Edge case: nama kosong/terlalu pendek → error inline; edit tanpa mengubah field tetap menyimpan
  `id` yang sama (tidak membuat duplikat).
- Ref: `lib/features/persona/`, `lib/models/persona_config.dart`.

### FR-04 — Model Install & Katalog — `Partial`

- 5 model (Qwen 2.5 1.5B default, Qwen 2.5 0.5B, SmolLM 135M, DeepSeek R1 1.5B, Gemma 3 1B)
  diunduh dari HuggingFace dengan progress dan tombol batal, **atau** file `.litertlm`/`.task`
  di-upload dari perangkat.
- Token HuggingFace opsional (model gated) disimpan di `SharedPreferences`.
- Setelah sukses: `modelVariant` = nama file, `modelSource` = `network`/`file`, `modelUrl` = URL.
- Restart: model terpasang dikenali lewat `isModelInstalled(nama file)`.
- ⚠️ `Partial`: belum ada preflight ruang penyimpanan/peringatan RAM rendah.
- Edge case: file dengan nama kustom tetap dikenali (identitas = nama file); upload ekstensi lain
  ditolak dengan pesan `modelFileInvalid`; batal unduhan menghasilkan status error yang ramah.
- Ref: `lib/features/model/model_download_screen.dart`, `lib/services/ai/model_service.dart`,
  `lib/services/ai/model_catalog.dart`.

---

## Chat & Suara

### FR-05 — Chat Streaming — `Partial`

- Input maksimum 2000 karakter; pesan user langsung dipersist dan tampil.
- Token AI muncul bertahap (bubble streaming), `TypingIndicator` sebelum token pertama.
- Riwayat lengkap dipersist di ObjectBox dan dimuat ulang saat app dibuka.
- ⚠️ `Partial`: tidak ada tombol stop-generation; input dinonaktifkan selama AI menjawab.
- Ref: `lib/features/chat/chat_screen.dart`, `lib/features/chat/chat_controller.dart`,
  `lib/services/ai/model_service.dart`.

### FR-06 — Voice Input (STT) — `Partial`

- Dua backend: on-device (Moonshine, rekam WAV 16 kHz mono) dan sistem (`speech_to_text`).
- Transkrip masuk ke input untuk diedit, lalu terkirim dengan `Message.isVoice = true`.
- Izin mikrofon diminta saat dipakai; penolakan → pesan `chatSttUnavailable`.
- ⚠️ `Partial`: tidak ada visualisasi waveform/progress transkripsi.
- Edge case: rekaman tanpa akhir → `stopListening` mengembalikan string kosong (tanpa error ke
  UI); WAV tanpa chunk `data` ditolak parser (`FormatException`) dan sesi dianggap gagal.
- Ref: `lib/services/stt_service.dart`, `lib/core/utils/wav_pcm.dart`,
  `lib/features/chat/widgets/input_bar.dart`.

### FR-07 — Voice Output (TTS) — `Partial`

- Dua backend: on-device (Inflect default, Matcha, Qwen3) dan suara sistem (`flutter_tts`).
- Play/stop per bubble AI; auto-play opsional setelah jawaban selesai.
- Bahasa TTS mengikuti `AppSettings.language` (`id-ID`/`en-US`).
- Ganti model benar-benar memasang/mengaktifkan model yang dipilih.
- ⚠️ `Partial`: selesai playback diperkirakan dari durasi PCM (bukan callback plugin).
- Edge case: model belum tersedia → SnackBar `chatTtsUnavailable`, chat tetap jalan; meninggalkan
  layar chat menghentikan audio.
- Ref: `lib/services/tts_service.dart`, `lib/features/chat/widgets/chat_bubble.dart`.

### FR-08 — Typing Indicator — `Implemented`

- Animasi tiga titik saat `ChatState.isTyping` dan belum ada token.
- Ref: `lib/features/chat/widgets/typing_indicator.dart`.

### FR-09 — Dynamic Mood Engine — `Implemented`

- 5 mood (happy, longing, playful, sad, excited) dengan intensitas 0–1.
- Diperbarui dari sentimen jawaban AI, turun ke `longing` setelah 6/12 jam idle.
- Mood diinjeksikan ke system prompt dan ditampilkan di AppBar + profile sheet.
- Ref: `lib/services/mood_service.dart`, `lib/features/chat/mood_provider.dart`,
  `lib/features/chat/widgets/mood_indicator.dart`.

### FR-10 — Persona Profile Sheet — `Implemented`

- Bottom sheet dari AppBar chat: avatar besar, nama, gender, panggilan, kartu mood (emoji +
  intensitas), chip hobi, kartu kepribadian, tombol Edit.
- Edit membuka `PersonaEditSheet` (bukan route), perubahan langsung terlihat.
- Ref: `lib/features/persona/persona_profile_sheet.dart`,
  `lib/features/persona/persona_edit_sheet.dart`.

---

## Memori & Konteks

### FR-11 — Memory Extraction — `Implemented`

- Setiap jawaban AI memicu ekstraksi fakta `FACT: category | key | value` (best-effort).
- Fakta digabung berdasarkan `key` (case-insensitive): nilai/kategori/sumber diperbarui, bukan
  duplikat. `sourceSnippet` menyimpan pesan user pemicu.
- `lastReferencedAt` diperbarui untuk setiap fakta yang dipakai menyusun prompt.
- Kategori: personal, event, preference, date.
- Edge case: model mengembalikan format salah → tidak ada fakta baru, chat tidak gagal.
- Ref: `lib/services/ai/memory_extractor.dart`, `lib/features/chat/chat_controller.dart`.

### FR-12 — Memory Screen — `Implemented`

- Daftar fakta per kategori, pencarian key/value, hapus satu fakta, reset semua fakta.
- Ref: `lib/features/memory/memory_screen.dart`, `lib/features/memory/memory_controller.dart`.

### FR-13 — Conversation Summarization — `Implemented`

- Setiap 30 pesan, ringkasan 3–5 kalimat dibuat (maks. 60 pesan terakhir) dan disimpan di
  `AppSettings.conversationSummary` lewat `AppSettingsNotifier.setConversationSummary`.
- Ringkasan diinjeksikan ke system prompt sebagai `[CONTEXT SUMMARY]`.
- Hapus semua percakapan dan reset persona menghapus ringkasan.
- Ref: `lib/services/ai/prompt_builder.dart`, `lib/features/settings/settings_controller.dart`.

### FR-14 — Content Safety — `Implemented`

- Gate input (sebelum prompt) dan output (setelah generasi) dengan kategori: explicit sexual,
  self-harm, professional advice, hate speech, violence instruction, PII.
- Konten terblokir diganti deflection hangat; tidak ada pesan error teknis ke UI.
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

### FR-16 — Check-in Notification — `Implemented` (interval tetap)

- Saat app masuk background (`paused`) dan fitur aktif, check-in dijadwalkan **1 jam** ke depan;
  dibatalkan saat app kembali (`resumed`).
- Interval belum bisa diubah pengguna (KI-07).
- Ref: `lib/features/notifications/app_lifecycle_observer.dart`,
  `lib/services/notification_service.dart`.

### FR-17 — Special Day Notification — `Backlog`

- API `scheduleSpecialDay`/`cancelSpecialDay` ada (tanggal masa depan saja, slot id), tetapi
  **belum ada UI** yang memanggilnya.
- Ref: `lib/services/notification_service.dart`; status: `KNOWN_ISSUES` KI-06.

---

## Settings & Privasi

### FR-18 — Settings — `Implemented`

- Section: Persona (ringkasan + edit + reset), Tampilan (light/dark/system), Bahasa
  (ID/EN/mixed), Suara (TTS on/off, auto-play, backend, model), Notifikasi (morning message,
  jam, check-in, izin), Data & Privasi.
- ⚠️ Belum ada layar Privacy Policy in-app (lihat FR-19/KI-10).
- Ref: `lib/features/settings/`.

### FR-19 — Data & Privasi — `Implemented`

- Hapus semua percakapan (+ ringkasan) → `chatProvider` disegarkan.
- Ekspor riwayat chat ke `.txt` di direktori dokumen.
- Reset persona: persona, memori, mood, ringkasan dihapus; kembali ke `/persona-setup`.
- Reset semua data: persona, memori, mood, pesan, settings dihapus; notifikasi dibatalkan;
  kembali ke `/age-gate`. File model + identitasnya dipertahankan (tidak unduh ulang).
- Semua aksi destruktif memakai dialog konfirmasi dengan label batal terlokalisasi.
- Ref: `lib/features/settings/widgets/data_privacy_section.dart`,
  `lib/features/settings/widgets/persona_section.dart`,
  `lib/features/settings/settings_controller.dart`.

### FR-20 — Bahasa (Indonesia / English / Mixed) — `Partial`

- `AppSettings.language` mengatur: string UI (`AppStrings`), locale Material
  (`GlobalMaterialLocalizations`), bahasa keluaran AI (instruksi di system prompt), dan bahasa
  TTS/STT.
- ⚠️ `Partial`: teks notifikasi, deflection safety, header ekspor, katalog hobi, dan
  `_friendlyError` masih Inggris/hardcode (KI-11).
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
| Model belum siap | guard menjaga di `/model-download`; aksi chat tidak tersedia |
| Model gagal dimuat | status error ramah di layar model, bisa unduh ulang |
| Izin mikrofon/notifikasi ditolak | fitur terkait nonaktif dengan pesan hangat |
| Penyimpanan penuh | tidak ditangani (KI-09/KI-14) |
| App dibunuh saat generasi | pesan user sudah tersimpan; jawaban parsial tidak |
| Data DB korup | tidak ada pemulihan otomatis (KI-14) |
| Tidak ada jaringan saat install | error ramah + tombol retry |
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
| FR-19 | `features/settings/widgets/data_privacy_section.dart` | ObjectBox (semua box) |
| FR-20 | `features/settings/widgets/language_section.dart` | `core/l10n/app_strings.dart`, `AppLanguage` |

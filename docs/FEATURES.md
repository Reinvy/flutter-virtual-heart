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

### FR-04 — Mesin AI (Model Lokal & Cloud BYOK) — `Implemented`

- Layar `/model-download` memiliki dua tab: **Lokal** (on-device) dan **Cloud BYOK** (lihat
  FR-28 & FR-29).
- Tab Lokal menyediakan 5 model (Qwen 2.5 1.5B default, Qwen 2.5 0.5B, SmolLM 135M, DeepSeek R1
  1.5B, Gemma 3 1B) diunduh dari HuggingFace dengan progress dan tombol batal, **atau** file
  `.litertlm`/`.task` di-upload dari perangkat.
- Token HuggingFace opsional (model gated) disimpan di `SharedPreferences`.
- Setelah sukses: `modelVariant` = nama file, `modelSource` = `network`/`file`, `modelUrl` = URL.
- Restart: mode aktif (`AppSettings.aiMode`) dipulihkan — bila `cloud`, profil BYOK aktif langsung
  siap tanpa memuat model lokal; bila `local`, model terpasang dikenali lewat
  `isModelInstalled(nama file)`. **Tidak ada** auto-download saat pertama buka.
- Ganti model lokal atau beralih ke/dari profil Cloud BYOK kapan saja lewat Settings → Model AI
  atau `/model-download`. Aktivasi profil Cloud menutup model lokal native agar RAM bebas.
- Error instalasi & koneksi cloud dipetakan ke kind (`network`/`auth`/`notFound`/`rateLimited`/
  `timeout`/`invalidConfig`/`storage`/`invalidFile`/`engine`/`unknown`) dan ditampilkan lewat
  `AppStrings`; batal unduhan memulihkan status sebelumnya tanpa banner error.
- ⚠️ Belum ada preflight ruang penyimpanan/peringatan RAM rendah untuk model lokal (KI-09).
- Ref: `lib/features/model/model_download_screen.dart`,
  `lib/features/model/cloud_provider_editor_sheet.dart`,
  `lib/services/ai/model_service.dart`, `lib/services/ai/model_catalog.dart`.

---

## Chat & Suara

### FR-05 — Chat Streaming — `Implemented`

- Batas input dinamis: 2000 karakter pada mode Lokal, atau hingga 64.000 karakter (default 12.000)
  mengikuti `AiProviderProfile.maxInputChars` pada mode Cloud BYOK (counter muncul pada 90%
  batas); pesan user dipersist setelah gate keamanan dan langsung tampil.
- Token AI muncul bertahap (bubble streaming, lokal maupun cloud multi-turn via Genkit),
  `TypingIndicator` sebelum token pertama.
- Tombol stop menggantikan tombol kirim selama generasi (membatalkan inferensi lokal maupun stream
  HTTP cloud); jawaban parsial disimpan dan banner "Jawaban terhenti" muncul. Kegagalan generasi
  menampilkan error terlokalisasi (`authError`, `rateLimited`, `timeout`, `invalidConfig`,
  `contextLimit`, `generationFailed`) + Coba Lagi.
- Riwayat lengkap dipersist di ObjectBox, diurutkan `(timestamp, id)`, dimuat ulang saat app
  dibuka, dan langsung menggulir ke pesan terbaru; auto-scroll hanya saat pengguna berada di
  bawah. Teks bubble bisa diseleksi.
- Markdown dari model tidak pernah memuat gambar jaringan (privacy).
- Ref: `lib/features/chat/chat_screen.dart`, `lib/features/chat/chat_controller.dart`,
  `lib/services/ai/model_service.dart`.

### FR-06 — Voice Input (STT) — `Partial`

- Lima backend independen (terpisah dari TTS): sistem (`speech_to_text`), on-device (Moonshine,
  rekam WAV 16 kHz mono), **ElevenLabs Scribe**, **OpenAI-compatible / Groq Whisper**, dan
  **Google Gemini** multimodal audio (lihat FR-30).
- Transkrip masuk ke input untuk diedit, lalu terkirim dengan `Message.isVoice = true`. Saat
  transkripsi cloud berlangsung, `InputBar` menampilkan indikator `isTranscribing`.
- Izin mikrofon diminta saat dipakai; penolakan → SnackBar `chatMicPermission` dengan aksi
  "Buka Pengaturan". Transkrip disisipkan di posisi kursor, bukan menimpa teks yang ada.
- TTS dihentikan sebelum mikrofon aktif; sesi ganda ditolak (`busy`).
- ⚠️ `Partial`: tidak ada visualisasi waveform selama perekaman.
- Edge case: rekaman tanpa akhir → `stopListening` mengembalikan string kosong; WAV tanpa chunk
  `data` ditolak parser (`FormatException`); file WAV sementara selalu dihapus di `finally`.
- Ref: `lib/services/stt_service.dart`, `lib/core/utils/wav_pcm.dart`,
  `lib/features/chat/widgets/input_bar.dart`.

### FR-07 — Voice Output (TTS) — `Partial`

- Lima backend independen (terpisah dari STT): suara sistem (`flutter_tts`), on-device (Inflect
  default, Matcha, Qwen3), **ElevenLabs** (browser suara akun + voice settings), **OpenAI /
  compatible**, dan **Google Gemini** (lihat FR-30).
- Play/stop per bubble AI (tombol disembunyikan saat TTS mati); auto-play opsional setelah
  jawaban selesai, hanya jika layar chat sedang aktif.
- Bahasa TTS mengikuti `AppSettings.language` (`id-ID`/`en-US`) dan diteruskan ke engine.
- Utterance baru membatalkan yang lama (termasuk membatalkan HTTP request Cloud TTS & membersihkan
  file audio sementara).
- ⚠️ `Partial`: pemilihan suara masih global (belum per persona, KI-05), dan selesai playback
  on-device PCM (`gemma`) masih diperkirakan via timer (KI-08); Cloud TTS sudah memakai callback
  akurat `AudioPlayer.onPlayerComplete`.
- Edge case: model/key belum tersedia → SnackBar terlokalisasi, chat tetap jalan; meninggalkan
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
  Memori dan Mesin AI (menampilkan status Lokal atau Cloud BYOK + profil aktif).
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
  (badge Lokal / Cloud BYOK, profil/model aktif, akses cepat **Parameter Cloud**, tombol Ganti
  Model), **Suara** (TTS on/off, auto-play, pilihan backend TTS dan STT terpisah, konfigurasi
  provider Cloud Speech, model lokal), Notifikasi (morning message, jam, check-in + interval,
  izin), Data & Privasi.
- Izin ditampilkan apa adanya: tile izin tidak memunculkan dialog saat layar dibuka, dan sakelar
  notifikasi menolak aktif tanpa izin OS (SnackBar panduan).
- Section dan bottom sheet memakai warna `ColorScheme` (kontras AA di light & dark) dan tidak
  overflow pada 320 dp.
- Ref: `lib/features/settings/`.

### FR-19 — Data & Privasi — `Implemented`

- Hapus semua percakapan (+ ringkasan + counter) dalam satu transaksi → `chatProvider` disegarkan.
- Ekspor riwayat chat ke `.txt` lewat dialog simpan OS (`FilePicker.saveFile`) dengan header
  terlokalisasi; API key BYOK tidak pernah masuk ekspor.
- Reset persona: persona, memori, mood, **percakapan**, ringkasan dihapus; kembali ke
  `/persona-setup`.
- Reset semua data: persona, memori, mood, pesan, settings, **seluruh profil Cloud BYOK**,
  **konfigurasi Cloud Speech**, **seluruh API key terenkripsi di `SecretStore`**, token
  HuggingFace, dan file ekspor dihapus; notifikasi dibatalkan; kembali ke `/age-gate`. File model
  lokal + identitasnya dipertahankan (mode kembali ke Lokal).
- Aksi destruktif menunggu generasi/unduhan berhenti dan memakai dialog konfirmasi terlokalisasi.
- Kebijakan privasi hybrid bisa dibaca di aplikasi (`/privacy`) dari age gate maupun Settings.
- Ref: `lib/features/settings/widgets/data_privacy_section.dart`,
  `lib/features/settings/widgets/persona_section.dart`,
  `lib/services/settings/settings_service.dart`, `lib/services/ai/secret_store.dart`.

### FR-20 — Bahasa (Indonesia / English / Mixed) — `Implemented`

- `AppSettings.language` mengatur: string UI (`AppStrings`), locale Material
  (`GlobalMaterialLocalizations`), bahasa keluaran AI (instruksi di system prompt), bahasa
  TTS/STT, body notifikasi, deflection safety, error model/cloud, header ekspor, dan kebijakan
  privasi.
- Tag hobi disimpan dalam bahasa Inggris di `PersonaConfig.hobbies`, sedangkan label UI
  dilokalisasi ke ID/EN lewat `AppStrings.personaHobbyLabel`.
- Ref: `lib/core/l10n/app_strings.dart`, `lib/services/ai/prompt_builder.dart`, `lib/app.dart`.

---

## Cloud AI BYOK & Cloud Speech (Genkit)

### FR-28 — Cloud AI Multi-Provider (BYOK via Genkit) — `Implemented`

- Mendukung multi-profil persisten untuk protokol **Google AI (Gemini)** (`genkit_google_genai`),
  **Anthropic & Anthropic-compatible** (`genkit_anthropic`), dan **OpenAI & OpenAI-compatible**
  (`genkit_openai`), dengan preset cepat (Google Gemini, Anthropic Claude, OpenAI, OpenRouter,
  Groq, DeepSeek, xAI Grok, Together, Ollama/LM Studio lokal, Custom Proxy).
- Custom `baseUrl` (tervalidasi & dinormalisasi) serta `customHeaders` JSON per profil.
- API key disimpan terenkripsi lewat `SecretStore` (`flutter_secure_storage`), opsional untuk
  endpoint jaringan lokal (`localhost` / RFC1918).
- Aksi **Test Connection** (probe dengan latensi ms) dan **Fetch Models** (daftar model langsung
  dari endpoint provider).
- Beralih 1-ketuk antar profil Cloud maupun kembali ke mode Lokal; verifikasi live API pihak ketiga
  tercatat `unverified` di `KNOWN_ISSUES` KI-25.
- Ref: `lib/models/ai_provider_profile.dart`, `lib/services/ai/genkit/`,
  `lib/services/ai/ai_provider_controller.dart`, `lib/features/model/cloud_provider_editor_sheet.dart`.

### FR-29 — Parameter Generasi & Kebebasan Konteks Cloud — `Implemented`

- Setiap profil Cloud BYOK memiliki parameter independen: `temperature`, `topP`, `topK`,
  `maxOutputTokens` (256–32768), `presencePenalty`, `frequencyPenalty`, `stopSequences`, `seed`,
  `reasoningEffort` / `thinkingBudgetTokens`, `geminiSafetyLevel`, `stripStreamOptions`, dan
  `timeoutSeconds` (15–300 detik).
- Sanitizer provider mencegah kombinasi parameter ilegal (misalnya Claude 4.5+ `temperature` + `topP`
  bersamaan atau sampling saat extended thinking aktif).
- Kebebasan konteks per profil: `maxHistoryMessages` (10–200), `maxMemoryFacts` (5–100),
  `maxInputChars` (2000–64000), `maxPromptChars` (6000–256000), toggle `enforceShortReply`,
  `customSystemPrompt`, serta `enableBackgroundTasks` + `backgroundModelId` lebih hemat untuk
  ekstraksi memori & ringkasan.
- Ref: `lib/services/ai/genkit/provider_config_builder.dart`, `lib/services/ai/prompt_builder.dart`,
  `lib/features/model/cloud_provider_editor_sheet.dart`.

### FR-30 — Cloud Voice (ElevenLabs, OpenAI-Compatible & Google Gemini TTS/STT) — `Implemented`

- Pemilihan backend TTS dan STT terpisah; mendukung `elevenlabs`, `openai` (termasuk preset Groq
  Whisper untuk STT), dan `google` selain `system` dan `gemma`.
- **ElevenLabs** melalui `ElevenLabsGenkitPlugin`: browser suara akun (`/v1/voices`) + preset
  suara, slider `stability`, `similarity_boost`, `style`, `speed`, toggle `use_speaker_boost`,
  pilihan format audio (default `mp3_44100_128`), serta STT `scribe_v2`/`scribe_v1` dengan
  `tag_audio_events` & `diarize`.
- **OpenAI & Compatible**: TTS (`gpt-4o-mini-tts` + `instructions`, `tts-1`, `tts-1-hd`, 11 suara)
  dan STT (`gpt-4o-mini-transcribe`, `whisper-1`, preset Groq `whisper-large-v3-turbo`), dengan
  opsi pakai ulang API key dari profil LLM OpenAI.
- **Google Gemini**: TTS (`gemini-2.5-flash-preview-tts` / `pro`, suara prebuilt + style prompt,
  PCM L16 → WAV) dan multimodal STT (`gemini-2.5-flash` / `pro`), dengan opsi pakai ulang API key
  dari profil LLM Google.
- Tombol **Tes Suara** di sheet konfigurasi; verifikasi live API & perangkat fisik tercatat di
  `KNOWN_ISSUES` KI-25.
- Ref: `lib/models/cloud_speech_config.dart`, `lib/services/ai/genkit/elevenlabs_plugin.dart`,
  `lib/features/settings/widgets/cloud_speech_sheet.dart`, `lib/services/tts_service.dart`,
  `lib/services/stt_service.dart`.

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
| FR-19 | `features/settings/widgets/data_privacy_section.dart`, `features/settings/privacy_screen.dart` | ObjectBox (7 box), `SecretStore`, `SharedPreferences` |
| FR-20 | `features/settings/widgets/language_section.dart` | `core/l10n/app_strings.dart`, `AppLanguage` |
| FR-28 | `features/model/model_download_screen.dart`, `features/model/cloud_provider_editor_sheet.dart` | `AiProviderProfile`, `SecretStore`, `services/ai/genkit/` |
| FR-29 | `features/model/cloud_provider_editor_sheet.dart`, `features/settings/widgets/model_section.dart` | `provider_config_builder.dart`, `PromptLimits` |
| FR-30 | `features/settings/widgets/voice_section.dart`, `features/settings/widgets/cloud_speech_sheet.dart` | `CloudSpeechConfig`, `ElevenLabsGenkitPlugin`, `TtsService`, `SttService` |

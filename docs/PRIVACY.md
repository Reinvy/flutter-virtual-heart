# PRIVACY — Data, Jaringan, dan Izin

VirtualHeart adalah aplikasi **privacy-first hybrid (on-device & Cloud BYOK opsional)**. Dokumen
ini menjelaskan apa yang disimpan, apa yang keluar dari perangkat, dan cara menghapusnya. Wording
di sini harus sinkron dengan `README.md`, `AppStrings.privacyPolicy`, dan `AppStrings.ageGateTerms`.

## 1. Data yang disimpan (lokal)

### ObjectBox (tidak terenkripsi, lokal perangkat)

| Data | Lokasi | Isi |
| --- | --- | --- |
| Percakapan | `messageBox` | teks pesan user & AI, timestamp, flag voice, mood saat jawab |
| Memori | `memoryFactBox` | fakta tentang user (key/value, kategori, potongan sumber) |
| Persona | `personaBox` | nama, gender, kepribadian, hobi, avatar |
| Mood | `moodStateBox` | mood + intensitas + waktu interaksi terakhir |
| Pengaturan | `appSettingsBox` | mode AI (`local`/`cloud`), profil cloud aktif, bahasa, tema, backend TTS/STT, jadwal + interval check-in, ringkasan percakapan, identitas model lokal |
| Profil Cloud BYOK | `aiProviderProfileBox` | nama profil, protokol, Base URL, Model ID, parameter generasi & konteks (tanpa API key) |
| Pengaturan Suara Cloud | `cloudSpeechConfigBox` | pilihan voice/model/slider ElevenLabs, OpenAI-compatible, Google Gemini (tanpa API key) |

Pesan yang diblokir content safety tetap disimpan dengan flag `isBlocked` + deflection-nya, tetapi
tidak pernah dikirim ke model (lokal maupun cloud) pada giliran berikutnya, tidak masuk ringkasan,
memori, atau mood.

### Penyimpanan Aman OS (`SecretStore` — `flutter_secure_storage`)

Seluruh **API key BYOK** (Google, Anthropic-compatible, OpenAI-compatible, ElevenLabs, Cloud
TTS/STT) disimpan terenkripsi menggunakan Keystore/Keychain OS (Android `allowBackup="false"`,
iOS Keychain). API key **tidak pernah** ditulis ke ObjectBox, `SharedPreferences`, log, maupun
file ekspor chat.

Ditambah `SharedPreferences` hanya untuk token HuggingFace opsional (`hf_token`).

Tidak ada akun, tidak ada sinkronisasi cloud, dan tidak ada backend/server aplikasi VirtualHeart.

## 2. Jaringan keluar

| Tujuan | Kapan | Data yang dikirim |
| --- | --- | --- |
| HuggingFace (`huggingface.co`) | saat mengunduh model LLM/STT/TTS lokal | permintaan HTTP file model; token Bearer bila diisi untuk model gated |
| Google Fonts (`fonts.gstatic.com`/`fonts.googleapis.com`) | saat aplikasi memuat font | permintaan font (metadata permintaan standar) |
| Endpoint Cloud BYOK LLM yang dikonfigurasi pengguna (Google, Anthropic/compat, OpenAI/compat) | **opsional**, hanya saat pengguna mengaktifkan mode Cloud BYOK, Test Connection, atau Fetch Models | system prompt (persona, mood, fakta memori, ringkasan), riwayat percakapan non-blocked, pesan terbaru, dan parameter generasi — dikirim **langsung dari perangkat** ke endpoint pilihan pengguna dengan API key milik pengguna |
| Endpoint Cloud Speech yang dikonfigurasi pengguna (ElevenLabs, OpenAI/Groq, Google Gemini) | **opsional**, hanya saat pengguna memilih backend TTS/STT Cloud dan memutar/merekam suara | teks balasan (TTS) atau rekaman audio WAV sementara (STT) — dikirim **langsung dari perangkat** ke endpoint pilihan pengguna |

- Pada **mode Lokal penuh** (LLM Lokal + TTS/STT Sistem atau On-device): isi percakapan, memori,
  persona, mood, dan suara **tidak pernah** dikirim ke mana pun.
- Pada **mode Cloud BYOK / Cloud Speech**: pemrosesan dan retensi data tunduk pada kebijakan
  privasi provider atau server self-hosted yang dipilih sendiri oleh pengguna. Tidak ada proxy
  atau server perantara VirtualHeart.
- Tidak ada analytics, crash reporting, atau iklan.

> Catatan: karena font diambil saat runtime, permintaan font dapat menyertakan IP pengguna ke
> Google. Ini tercatat sebagai keterbatasan di `KNOWN_ISSUES.md`; solusinya adalah membundel font.

## 3. Izin OS

| Izin | Dipakai untuk | Wajib? |
| --- | --- | --- |
| Mikrofon (`RECORD_AUDIO`) | STT on-device, STT Cloud (rekam WAV sementara), & dikte sistem | hanya saat fitur suara dipakai |
| Notifikasi (`POST_NOTIFICATIONS`) | morning message & check-in | opsional |
| Exact alarm (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`) | jadwal notifikasi tepat waktu; bila ditolak, jadwal jatuh ke mode inexact | opsional |
| Bluetooth | headset mikrofon | opsional |
| Boot completed | memulihkan jadwal notifikasi setelah reboot | opsional |

Mencabut izin: Settings OS → Apps → VirtualHeart → Permissions. Aplikasi tetap berjalan; fitur
terkait menampilkan pesan hangat (`chatSttUnavailable`, dsb.).

## 4. Menghapus data

| Aksi | Efek |
| --- | --- |
| Hapus satu profil Cloud BYOK | profil dihapus dari ObjectBox dan API key terkait dihapus dari `SecretStore` |
| Settings → Hapus semua percakapan | semua pesan + ringkasan konteks + counter ringkasan dihapus |
| Settings → Reset persona | persona, memori, mood, **seluruh percakapan**, dan ringkasan dihapus; setup persona diulang |
| Settings → Reset semua data | persona, memori, mood, pesan, pengaturan, seluruh profil Cloud BYOK, konfigurasi Cloud Speech, **seluruh API key BYOK terenkripsi**, token HuggingFace, dan file ekspor `virtualheart_*.txt` dihapus; notifikasi dibatalkan; aplikasi kembali ke gerbang usia (mode kembali ke Lokal) |
| Uninstall aplikasi | seluruh data lokal, keystore aplikasi, dan file model ikut terhapus |

File model lokal yang sudah diunduh **tidak** dihapus oleh tombol reset (agar tidak mengunduh ulang
1–2 GB). Hapus lewat uninstall atau pengelola penyimpanan OS.

Ekspor chat memakai dialog simpan OS sehingga pengguna memilih lokasi file; pada platform tanpa
dialog simpan, file ditulis ke dokumen aplikasi dan path lengkapnya ditampilkan di SnackBar.
Kebijakan privasi yang sama bisa dibaca di aplikasi (age gate → "Baca Kebijakan Privasi", atau
Settings → Data & Privasi → "Kebijakan Privasi").

## 5. Batasan usia & keselamatan

- Aplikasi untuk pengguna **13 tahun ke atas** (gerbang usia di awal, `isAgeVerified`).
- Bukan pengganti bantuan profesional: prompt melarang nasihat medis/hukum/finansial, dan
  `ContentSafety` memblokir kategori `selfHarm`, `professionalAdvice`, `explicitSexual`,
  `hateSpeech`, `violenceInstruction`, `personaBreak` dengan deflection hangat pada mode Lokal
  maupun Cloud BYOK.
- Aplikasi tidak memverifikasi identitas dan tidak menghubungi layanan darurat.

## 6. Model AI

- Pada **mode Lokal**, model berjalan sepenuhnya di perangkat (Qwen/SmolLM/DeepSeek/Gemma);
  satu-satunya penyaringan adalah `ContentSafety` di aplikasi.
- Pada **mode Cloud BYOK**, kualitas, bias, dan penyaringan sisi provider bergantung pada model
  serta endpoint yang dipilih pengguna (selain `ContentSafety` di aplikasi).

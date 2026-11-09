# PRIVACY — Data, Jaringan, dan Izin

VirtualHeart adalah aplikasi **on-device**. Dokumen ini menjelaskan apa yang disimpan, apa yang
keluar dari perangkat, dan cara menghapusnya. Wording di sini harus sinkron dengan `README.md`
dan `AppStrings.ageGateTerms`/`ageGateBody` bila menyangkut komitmen privasi.

## 1. Data yang disimpan (lokal, ObjectBox)

| Data | Lokasi | Isi |
| --- | --- | --- |
| Percakapan | `messageBox` | teks pesan user & AI, timestamp, flag voice, mood saat jawab |
| Memori | `memoryFactBox` | fakta tentang user (key/value, kategori, potongan sumber) |
| Persona | `personaBox` | nama, gender, kepribadian, hobi, avatar |
| Mood | `moodStateBox` | mood + intensitas + waktu interaksi terakhir |
| Pengaturan | `appSettingsBox` | bahasa, tema, TTS/STT, jadwal notifikasi, ringkasan percakapan, identitas model |

Ditambah `SharedPreferences` untuk token HuggingFace opsional (`hf_token`).

Tidak ada akun, tidak ada sinkronisasi cloud, tidak ada backend aplikasi.

## 2. Jaringan keluar

| Tujuan | Kapan | Data yang dikirim |
| --- | --- | --- |
| HuggingFace (`huggingface.co`) | saat mengunduh model LLM/STT/TTS | permintaan HTTP file model; token Bearer bila diisi untuk model gated |
| Google Fonts (`fonts.gstatic.com`/`fonts.googleapis.com`) | saat aplikasi memuat font | permintaan font (metadata permintaan standar) |

Yang **tidak** pernah dikirim: isi chat, memori, persona, mood, pengaturan, statistik penggunaan.
Tidak ada analytics, crash reporting, atau iklan.

> Catatan: karena font diambil saat runtime, permintaan font dapat menyertakan IP pengguna ke
> Google. Ini tercatat sebagai keterbatasan di `KNOWN_ISSUES.md`; solusinya adalah membundel font.

## 3. Izin OS

| Izin | Dipakai untuk | Wajib? |
| --- | --- | --- |
| Mikrofon (`RECORD_AUDIO`) | STT on-device & dikte sistem | hanya saat fitur suara dipakai |
| Notifikasi (`POST_NOTIFICATIONS`) | morning message & check-in | opsional |
| Exact alarm (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`) | jadwal notifikasi tepat waktu; bila ditolak, jadwal jatuh ke mode inexact | opsional |
| Bluetooth | headset mikrofon | opsional |
| Boot completed | memulihkan jadwal notifikasi setelah reboot | opsional |

Mencabut izin: Settings OS → Apps → VirtualHeart → Permissions. Aplikasi tetap berjalan; fitur
terkait menampilkan pesan hangat (`chatSttUnavailable`, dsb.).

## 4. Menghapus data

| Aksi | Efek |
| --- | --- |
| Settings → Hapus semua percakapan | semua pesan + ringkasan konteks dihapus |
| Settings → Reset persona | persona, memori, mood, ringkasan dihapus; setup persona diulang |
| Settings → Reset semua data | persona, memori, mood, pesan, pengaturan dihapus; notifikasi dibatalkan; aplikasi kembali ke gerbang usia |
| Uninstall aplikasi | seluruh data lokal + file model ikut terhapus |

File model yang sudah diunduh **tidak** dihapus oleh tombol reset (agar tidak mengunduh ulang
1–2 GB). Hapus lewat uninstall atau pengelola penyimpanan OS.

## 5. Batasan usia & keselamatan

- Aplikasi untuk pengguna **13 tahun ke atas** (gerbang usia di awal, `isAgeVerified`).
- Bukan pengganti bantuan profesional: prompt melarang nasihat medis/hukum/finansial, dan
  `ContentSafety` memblokir kategori `selfHarm`, `professionalAdvice`, `explicitSexual`,
  `hateSpeech`, `violenceInstruction`, `pii` dengan deflection hangat.
- Aplikasi tidak memverifikasi identitas dan tidak menghubungi layanan darurat.

## 6. Model AI

Model berjalan sepenuhnya di perangkat. Kualitas dan bias keluaran bergantung pada model yang
dipilih (Qwen/SmolLM/DeepSeek/Gemma). Tidak ada penyaringan server; satu-satunya penyaringan
adalah `ContentSafety` di aplikasi.

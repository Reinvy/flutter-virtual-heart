# KNOWN_ISSUES — Keterbatasan & Bug yang Diketahui

Dokumen **current-state**. Setiap kali menemukan bug baru atau menyelesaikan yang lama, ubah
tabel ini pada commit yang sama. Status: `open`, `partial`, `backlog`, `fixed`.

Kolom **Bukti** menyebut path + nama simbol (nomor baris sengaja tidak dipakai karena cepat
bergeser).

## 1. Platform

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-01 | tinggi | Web | `lib/features/settings/widgets/data_privacy_section.dart`, `lib/services/stt_service.dart`, `lib/features/model/model_download_screen.dart` (semua `dart:io`) | open | Web tidak didukung; tidak ada fallback. `web/index.html` menyatakan ini eksplisit. |
| KI-02 | sedang | macOS/Linux/Windows | `linux/`, `windows/`, `macos/` | open | Desktop eksperimental, tidak diuji di CI; rekaman Linux butuh `parecord`/`ffmpeg`. |
| KI-03 | sedang | iOS/macOS | `ios/Podfile`, `macos/Runner.xcodeproj` | open | Konfigurasi sudah disetel (iOS 16, macOS 14, entitlements) tetapi build belum pernah dijalankan di lingkungan ini (tanpa Xcode). |

## 2. Fitur yang belum lengkap

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-04 | tinggi | Chat | `lib/features/chat/chat_screen.dart`, `lib/features/chat/widgets/input_bar.dart` | open | Tidak ada tombol **stop generation**; input dinonaktifkan selama AI menjawab (`enabled: !isTyping`). Respons panjang tidak bisa dihentikan pengguna. |
| KI-05 | sedang | Chat | `lib/features/chat/chat_screen.dart` (`_speakMessage`) | backlog | Tidak ada pemilihan suara per persona; suara bersifat global (`AppSettings.tts*`). FR-03/FR-07 `Partial`. |
| KI-06 | rendah | Notifikasi | `lib/services/notification_service.dart` (`scheduleSpecialDay`) | backlog | API special-day tersedia tetapi belum ada UI (FR-17 `Backlog`). |
| KI-07 | sedang | Notifikasi | `lib/services/notification_service.dart` (`scheduleCheckinNotification`) | open | Interval check-in tetap 1 jam; belum ada UI untuk mengubahnya (FR-16). |
| KI-08 | rendah | Speech | `lib/services/tts_service.dart` (`_speakOnDevice`) | open | Selesai playback TTS diperkirakan dari durasi PCM (timer), bukan callback plugin; kalimat terakhir bisa terpotong/berlebih. |
| KI-09 | sedang | Model | `lib/services/ai/model_service.dart` | open | Tidak ada preflight ruang penyimpanan / peringatan RAM rendah sebelum mengunduh model 0.1–1.7 GB. |
| KI-10 | sedang | UI | `lib/features/persona/persona_profile_sheet.dart` | partial | Tidak ada layar Privacy Policy in-app; informasi privasi hanya di `docs/PRIVACY.md` dan README. |

## 3. Lokalisasi

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-11 | sedang | i18n | `lib/services/notification_service.dart` (template `_morningMessages`/`_checkinMessages`), `lib/services/ai/content_safety.dart` (redirect), `lib/features/settings/widgets/data_privacy_section.dart` (header ekspor), `lib/services/ai/model_service.dart` (`_friendlyError`), `lib/features/persona/persona_setup_screen.dart` (katalog hobi) | partial | Teks ini masih Inggris/hardcode dan tidak mengikuti `AppLanguage`. Material locale + prompt bahasa AI sudah diperbaiki. |

## 4. Data & arsitektur

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-12 | rendah | ObjectBox | `lib/services/database/objectbox_service.dart` (`getOrCreateSettings`) | open | Konvensi single-row (`getAll().first`) tidak dipaksakan; tidak ada `@Unique`. Baris ganda secara teori bisa muncul. |
| KI-13 | rendah | ObjectBox | `lib/services/database/objectbox_service.dart` (`close`) | open | `close()` tidak dipanggil; store hidup selama proses (sesuai desain aplikasi mobile). |
| KI-14 | rendah | Data | `lib/services/database/objectbox_service.dart` | open | Tidak ada pemulihan untuk DB korup (mis. proses terbunuh saat tulis) atau penanganan penyimpanan penuh. |
| KI-15 | rendah | Theme | `lib/core/design/tokens/app_colors.dart`, beberapa widget | partial | Beberapa warna/ukuran mentah masih ditulis langsung di widget; default `AppTextStyles` sudah mengikuti theme (dark-mode aman). |

## 5. Rilis & supply chain

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-16 | tinggi | Rilis | `android/app/build.gradle.kts` (`namespace`/`applicationId`, `signingConfig`) | open | Application ID masih `com.example.edge_chat` dan release ditandatangani kunci debug. Wajib diganti sebelum publikasi. |
| KI-17 | rendah | Privasi | `lib/core/design/app_theme.dart` (`GoogleFonts`) | open | Font diambil saat runtime (butuh jaringan, IP terkirim ke Google Fonts). Bundling font lokal menghilangkan ketergantungan ini. |
| KI-18 | sedang | Test | `test/` | open | Engine AI, `TtsService`/`SttService`, notifikasi, dan `ModelServiceNotifier` belum punya test otomatis (butuh plugin native/model). Lihat `TESTING.md` §2. |

## 6. Historis

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-19 | info | Dokumen | `docs/AUDIT_2026-11.md` | fixed | Snapshot audit 2026-11-09; jangan diperbarui — status terkini ada di dokumen ini. |

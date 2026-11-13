# KNOWN_ISSUES — Keterbatasan & Bug yang Diketahui

Dokumen **current-state**. Setiap kali menemukan bug baru atau menyelesaikan yang lama, ubah
tabel ini pada commit yang sama. Status: `open`, `partial`, `backlog`, `fixed`, `unverified`.

Kolom **Bukti** menyebut path + nama simbol (nomor baris sengaja tidak dipakai karena cepat
bergeser).

## 1. Platform

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-01 | tinggi | Web | `lib/features/settings/widgets/data_privacy_section.dart`, `lib/services/stt_service.dart`, `lib/features/model/model_download_screen.dart` (semua `dart:io`) | open | Web tidak didukung; tidak ada fallback. `web/index.html` menyatakan ini eksplisit. |
| KI-02 | sedang | macOS/Linux/Windows | `linux/`, `windows/`, `macos/` | open | Desktop eksperimental, tidak diuji di CI; rekaman Linux butuh `parecord`/`ffmpeg`. |
| KI-03 | sedang | iOS/macOS | `ios/Podfile`, `macos/Runner.xcodeproj` | open | Konfigurasi disetel (iOS 16, macOS 14, entitlements, macro `PERMISSION_MICROPHONE`/`PERMISSION_SPEECH_RECOGNIZER`), tetapi build belum pernah dijalankan di lingkungan ini (tanpa Xcode). |
| KI-20 | tinggi | Semua runtime native | `lib/services/ai/model_service.dart`, `lib/services/tts_service.dart`, `lib/services/stt_service.dart`, `lib/services/notification_service.dart` | unverified | Stop-generation, ganti model, TTS bahasa, STT izin ditolak, tap notifikasi, dan dialog simpan ekspor hanya bisa diverifikasi di perangkat. Logika sudah diimplementasi + dianalisis statis; jangan mengklaim lulus sebelum dicoba. |

## 2. Fitur & perilaku

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-05 | sedang | Chat | `lib/features/chat/chat_screen.dart` (`_speakMessage`) | backlog | Tidak ada pemilihan suara per persona; suara bersifat global (`AppSettings.tts*`). FR-03/FR-07 `Partial`. |
| KI-06 | rendah | Notifikasi | `lib/services/notification_service.dart` (`scheduleSpecialDay`) | backlog | API special-day tersedia tetapi belum ada UI (FR-17 `Backlog`). |
| KI-08 | rendah | Speech | `lib/services/tts_service.dart` (`_speakOnDevice`) | open | Selesai playback TTS diperkirakan dari durasi PCM (timer), bukan callback plugin; kalimat terakhir bisa terpotong/berlebih. |
| KI-09 | sedang | Model | `lib/services/ai/model_service.dart` | open | Tidak ada preflight ruang penyimpanan / peringatan RAM rendah sebelum mengunduh model 0.1–1.7 GB. Error `storage` baru muncul setelah kegagalan OS. |
| KI-21 | rendah | Chat | `lib/features/chat/widgets/chat_bubble.dart` (`_BubbleContent`) | fixed | Sintaks gambar markdown dari model (tanda `!` + alt + target dalam tanda kurung) dibuang dan `imageBuilder` mengembalikan `SizedBox.shrink()`, sehingga AI tidak bisa memicu permintaan jaringan. Efek samping: gambar markdown tidak pernah tampil (trade-off privasi yang disengaja). |
| KI-22 | rendah | Persona | `lib/core/l10n/app_strings.dart` (`personaHobbyLabel`), `lib/features/persona/persona_options.dart` (`kHobbiesList`) | fixed | Tag di `PersonaConfig.hobbies` tetap bahasa Inggris agar stabil lintas migrasi, sementara label UI sudah diterjemahkan ID/EN lewat `AppStrings.personaHobbyLabel`. |

## 3. Lokalisasi

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-11 | rendah | i18n | `lib/services/notification_service.dart` (fallback channel copy), `lib/features/settings/widgets/data_privacy_section.dart` (nama file ekspor) | partial | Deflection safety, error model, header ekspor, body notifikasi, dan kebijakan privasi sudah lewat `AppStrings`. Sisa hardcode hanya nama channel Android (tidak terlihat sebagai kalimat UI) dan nama file ekspor. |

## 4. Data & arsitektur

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-12 | rendah | ObjectBox | `lib/services/database/objectbox_service.dart` (`getOrCreateSettings`), `lib/features/persona/persona_controller.dart` (`build`), `lib/services/mood_service.dart` (`getCurrentMood`) | fixed | Baris ganda dibersihkan saat boot (id terkecil dipakai, sisanya dihapus). Belum ada `@Unique`; kanonikalisasi tetap dilakukan di kode. |
| KI-13 | rendah | ObjectBox | `lib/services/database/objectbox_service.dart` (`close`) | open | `close()` tidak dipanggil; store hidup selama proses (sesuai desain aplikasi mobile). |
| KI-14 | rendah | Data | `lib/services/database/objectbox_service.dart` (`create`) | partial | Store yang tidak bisa dibuka diganti nama menjadi `virtualheartdb.corrupt-<timestamp>` lalu dibuka ulang; kegagalan kedua memunculkan `BootstrapErrorApp`. Penyimpanan penuh dan file korup di tengah operasi belum ditangani. |
| KI-15 | rendah | Theme | `lib/core/design/tokens/app_colors.dart`, beberapa widget | partial | Warna eksplisit sekarang memakai `AppColors.*For(context)`/`ColorScheme` (dijaga `test/core/design_contrast_test.dart` ≥ 4.5:1), tetapi beberapa ukuran mentah masih ditulis langsung di widget. |
| KI-18 | sedang | Test | `test/` | partial | Fungsi murni, lock FIFO, clamping entity, router, controller `ChatNotifier` (dengan fake store/model), dan widget inti sudah dites. Inferensi model native end-to-end, `TtsService`/`SttService` plugin, dan notifikasi OS tetap butuh perangkat (lihat `TESTING.md`). |
| KI-23 | rendah | Test | `lib/objectbox.g.dart` | fixed | `test/core/objectbox_settings_test.dart` sekarang benar-benar berjalan (library native diunduh `install.sh`; CI gagal bila tidak ada) dan `make gen-check` mendeteksi drift binding. |
| KI-24 | sedang | UI/visual | `lib/core/design/components/main_shell_scaffold.dart`, `lib/core/design/tokens/app_colors.dart`, `lib/features/hub/companion_hub_screen.dart` | unverified | Redesign sistem **Multi-Theme Atelier** (4 preset × Light/Dark) & navigasi 4-tab diverifikasi lewat harness widget-test (kontras 8 palet, 320 dp overflow, shell 4-tab, Hub → Chat) dan `make apk`. Tampilan runtime di perangkat Android/iOS fisik (rendering font Google Fonts, sheet, audio lifecycle lintas tab) belum diverifikasi di perangkat nyata. |

## 5. Rilis & supply chain

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-16 | tinggi | Rilis | `android/app/build.gradle.kts` (`namespace`/`applicationId`, `signingConfig`) | open | Application ID masih `com.example.edge_chat` dan release ditandatangani kunci debug. Wajib diganti sebelum publikasi. |
| KI-17 | rendah | Privasi | `lib/core/design/app_theme.dart` (`GoogleFonts`) | open | Font diambil saat runtime (butuh jaringan, IP terkirim ke Google Fonts). Bundling font lokal menghilangkan ketergantungan ini. |

## 6. Historis

| ID | Severity | Area | Bukti | Status | Catatan |
| --- | --- | --- | --- | --- | --- |
| KI-19 | info | Dokumen | `docs/AUDIT_2026-11.md` | fixed | Snapshot audit 2026-11-09; jangan diperbarui — status terkini ada di dokumen ini. |
| KI-04 | tinggi | Chat | `lib/features/chat/widgets/input_bar.dart` | fixed | Tombol stop generation tersedia; jawaban parsial disimpan; banner error + Coba Lagi. |
| KI-07 | sedang | Notifikasi | `lib/services/notification_service.dart`, `lib/features/settings/widgets/notifications_section.dart` | fixed | Interval check-in dapat dipilih (1/3/6/12 jam) dan body mengikuti bahasa app. |
| KI-10 | sedang | UI | `lib/features/settings/privacy_screen.dart` | fixed | Kebijakan privasi tersedia di aplikasi dan bisa dibuka dari age gate + Settings. |

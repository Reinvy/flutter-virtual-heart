# DEPENDENCIES — Toolchain & Paket

Versi di bawah adalah kondisi `pubspec.yaml`/`.fvmrc` saat ini. Blok **DEPENDENCY FACTS** di
akhir dokumen bersifat mesin-terbaca: `tool/check_docs.dart` membandingkannya dengan
`pubspec.yaml` dan `.fvmrc`, dan CI gagal bila berbeda.

## 1. Toolchain

| Komponen | Versi | Catatan |
| --- | --- | --- |
| Flutter | **3.47.1** (`.fvmrc`) | jangan diubah tanpa task tersendiri |
| Dart | **3.13.1** | dibawa Flutter 3.47.1 |
| Android Gradle Plugin | **9.1.0** | lihat catatan pin di §5 |
| Gradle wrapper | **9.3.1** | |
| Kotlin plugin | **2.4.0** | `org.jetbrains.kotlin.android`, `android.newDsl=false` |
| JDK | 17+ (host pengembangan: 25) | `jvmTarget = JVM_17` |
| compileSdk / minSdk / targetSdk | 37 / 30 / 36 (`flutter.targetSdkVersion`) | wajib 37 untuk `flutter_local_notifications 23` |
| NDK | `flutter.ndkVersion` (28.2.13676358) | |
| iOS deployment target | 16.0 | syarat `flutter_edge_ai_mediapipe` |
| macOS deployment target | 14.0 | |

## 2. Dependency langsung

| Paket | Constraint | Fungsi | Catatan |
| --- | --- | --- | --- |
| `material_ui` | `^1.10.0` | widget Material | wajib: `google_fonts 9`, `gpt_markdown 1.4`, `flutter_riverpod 3.5`, `go_router 18` memakai tipe `material_ui` |
| `flutter_edge_ai` | `^2.6.0` | facade model/inference | pengganti `flutter_gemma` (discontinued) |
| `flutter_edge_ai_litertlm` | `^1.20.0` | engine `.litertlm` | `LiteRtLmEngine` |
| `flutter_edge_ai_mediapipe` | `^1.3.0` | engine `.task` | `MediaPipeEngine` |
| `flutter_edge_ai_speech` | `^0.6.0` | STT/TTS on-device | `LiteRtSttBackend`, `LiteRtTtsBackend` |
| `flutter_riverpod` | `^3.5.0` | state management | provider manual, tanpa codegen |
| `objectbox` / `objectbox_flutter_libs` | `^5.3.2` | database lokal | binding generated |
| `path_provider` | `^2.1.6` | direktori app | |
| `go_router` | `^18.1.3` | navigasi | guard murni `resolveRedirect` |
| `google_fonts` | `^9.0.0` | Fraunces + Plus Jakarta Sans | fetch runtime (lihat PRIVACY) |
| `flutter_animate` | `^4.5.2` | animasi deklaratif | |
| `flutter_svg` | `^2.3.2` | aset SVG | |
| `gpt_markdown` | `^1.4.1` | render markdown jawaban | |
| `record` | `^7.1.2` | rekam WAV 16 kHz | `record_linux 2.1.x` mendukung stream, app tetap memakai file WAV |
| `flutter_pcm_sound` | `^3.3.3` | playback PCM | |
| `file_picker` | `^13.3.2` | upload model | API statis `FilePicker.pickFile()` |
| `flutter_tts` | `^4.2.5` | TTS sistem | |
| `speech_to_text` | `^7.5.0` | STT sistem | |
| `flutter_local_notifications` | `^23.0.0` | notifikasi lokal | `initialize(settings:)`, `zonedSchedule(...)` |
| `flutter_timezone` | `^5.1.1` | zona waktu perangkat | dipakai sebelum menjadwalkan |
| `timezone` | `^0.11.2` | `TZDateTime` | database `latest_all` |
| `intl` | `^0.20.3` | format tanggal | |
| `permission_handler` | `^13.0.2` | izin mikrofon | |
| `shared_preferences` | `^2.5.6` | token HF + flag ringan | |

## 3. Dev dependency & pin

| Paket | Constraint | Alasan |
| --- | --- | --- |
| `flutter_lints` | `^6.0.0` | rules standar |
| `build_runner` | **`2.15.1`** (exact) | `objectbox_generator 5.3.2` butuh `analyzer <11` & `build <5.0.0`; `build_runner >=2.15.2` butuh `analyzer >=13.3` |
| `objectbox_generator` | **`5.3.2`** (exact) | harus sepadan dengan `objectbox 5.3.2`; ObjectBox 6 belum stabil |
| `yaml` | `^3.1.3` | dipakai `tool/check_docs.dart` |

Tidak ada `dependency_overrides` (aturan CI).

## 4. Paket yang dihapus/diganti

| Sebelum | Sekarang | Alasan |
| --- | --- | --- |
| `flutter_gemma`, `flutter_gemma_litertlm`, `flutter_gemma_mediapipe`, `flutter_gemma_speech` | `flutter_edge_ai*` | paket lama discontinued |
| `cupertino_icons` | — | tidak dipakai (Material + ikon SVG) |
| `lottie` | — | tidak ada aset animasi |
| `uuid` | — | tidak dipakai (id ObjectBox) |
| `dependency_overrides: record_platform_interface 1.0.2` | — | `record 7.1.x` + `record_linux 2.1.x` sudah saling cocok |
| aset `assets/models/` | — | model diunduh/di-upload, tidak dibundel |

## 5. Pin yang disengaja & sisa `pub outdated`

| Paket | Diresolusi | Versi terbaru | Alasan pin |
| --- | --- | --- | --- |
| `build_runner` | 2.15.1 | 2.15.x/2.17 | konflik `analyzer`/`build` dengan `objectbox_generator 5.3.2` |
| `objectbox_generator` | 5.3.2 | 5.3.2 | satu-satunya versi yang cocok dengan `objectbox 5.3.2` |
| AGP | 9.1.0 | 9.1.1 | 9.1.1 menjadikan accessor DSL lama (blok `android` pada `BaseAppModuleExtension`) **error** kompilasi skrip, sedangkan `org.jetbrains.kotlin.android` belum kompatibel dengan new DSL AGP 9 — Flutter 3.47.1 masih memakai DSL lama (`android.newDsl=false`). 9.0.1 tidak bisa dipakai karena `androidx.core 1.19.0` menuntut AGP >= 9.1.0. |

Paket transitif lain yang tertinggal mengikuti constraint di atas; cek berkala dengan
`fvm flutter pub outdated`.

Workaround build (bukan pin versi): `android/build.gradle.kts` menaikkan `compileSdk`
subproject library ke 37 karena `flutter_pcm_sound` masih memakai `compileSdkVersion 33`
dan dependency androidx-nya menuntut 34+. Hapus blok tersebut bila plugin sudah diperbarui.

## 6. Prosedur upgrade

1. Cek pub.dev: versi terbaru, changelog, batasan SDK/platform, dan apakah paket sudah
   discontinued (cari penerusnya).
2. Perbarui `pubspec.yaml` (hornati pin di §3).
3. `fvm flutter pub get` -> selesaikan konflik dengan menyesuaikan constraint, bukan override.
4. Bila API berubah: perbarui call site (grep nama simbol lama sampai nol).
5. Bila entity berubah: `fvm dart run build_runner build --delete-conflicting-outputs`.
6. `fvm flutter analyze`, `fvm flutter test`, `make apk` (bila Android tersentuh).
7. Perbarui dokumen ini + blok mesin + `README.md`/`docs/PLATFORM_SETUP.md` bila relevan.

## 7. Catatan platform

- Web tidak didukung (`dart:io` di settings/export/model/STT/notifikasi; speech web tidak
  tersedia).
- Desktop (Linux/Windows) eksperimental; rekaman Linux membutuhkan `parecord`/`ffmpeg` sesuai
  dokumentasi `record`.

## 8. Blok mesin

<!-- BEGIN DEPENDENCY FACTS
```yaml
flutter: 3.47.1
dependencies:
  material_ui: ^1.10.0
  flutter_edge_ai: ^2.6.0
  flutter_edge_ai_litertlm: ^1.20.0
  flutter_edge_ai_mediapipe: ^1.3.0
  flutter_edge_ai_speech: ^0.6.0
  flutter_riverpod: ^3.5.0
  objectbox: ^5.3.2
  objectbox_flutter_libs: ^5.3.2
  path_provider: ^2.1.6
  go_router: ^18.1.3
  google_fonts: ^9.0.0
  flutter_animate: ^4.5.2
  flutter_svg: ^2.3.2
  gpt_markdown: ^1.4.1
  record: ^7.1.2
  flutter_pcm_sound: ^3.3.3
  file_picker: ^13.3.2
  flutter_tts: ^4.2.5
  speech_to_text: ^7.5.0
  flutter_local_notifications: ^23.0.0
  flutter_timezone: ^5.1.1
  timezone: ^0.11.2
  intl: ^0.20.3
  permission_handler: ^13.0.2
  shared_preferences: ^2.5.6
dev_dependencies:
  flutter_lints: ^6.0.0
  build_runner: 2.15.1
  objectbox_generator: 5.3.2
  yaml: ^3.1.3
```
END DEPENDENCY FACTS -->

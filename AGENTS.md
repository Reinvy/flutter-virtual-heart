# AGENTS.md — Aturan Kerja VirtualHeart

Dokumen ini **otoritatif** untuk siapa pun (manusia atau agent) yang mengubah repositori ini.
Aturan di sini menang atas dokumen lain. Semua path relatif terhadap root repo.

## 1. Identitas & Lingkup

VirtualHeart adalah aplikasi pendamping romantis **on-device**: inferensi LLM, STT, dan TTS
berjalan di perangkat pengguna memakai `flutter_edge_ai`. Tidak ada server aplikasi, tidak ada
akun, tidak ada telemetri.

| Platform | Status |
| --- | --- |
| Android | **Didukung** (arm64-v8a, minSdk 30, compileSdk 37) |
| iOS | **Didukung** (deployment target 16.0) — belum diverifikasi di CI |
| macOS | **Eksperimental** (target 14.0) — belum diverifikasi di CI |
| Linux / Windows | **Eksperimental** — belum diverifikasi di CI |
| Web | **Tidak didukung** (banyak `dart:io`, speech web tidak tersedia) |

## 2. Peta Sumber Kebenaran

| Dokumen | Isi | Kapan diperbarui |
| --- | --- | --- |
| `AGENTS.md` (ini) | aturan kerja & Definition of Done | saat proses/aturan berubah |
| `docs/README.md` | indeks dokumen + aturan dokumen historis | saat menambah/menghapus dokumen |
| `docs/ARCHITECTURE.md` | init flow, tree `lib/`, provider, routing, layer | saat struktur/komposisi berubah |
| `docs/FEATURES.md` | spesifikasi & **status** tiap FR | saat perilaku fitur berubah |
| `docs/DESIGN.md` | token, komponen, navigasi, aksesibilitas | saat token/komponen berubah |
| `docs/DEPENDENCIES.md` | versi toolchain & paket (+ blok mesin) | saat dependency berubah |
| `docs/DATA_MODEL.md` | entity ObjectBox, box, reset flow | saat entity berubah |
| `docs/AI_PIPELINE.md` | katalog model, prompt, memori, mood, speech | saat pipeline AI berubah |
| `docs/PLATFORM_SETUP.md` | setup Android/iOS/macOS/desktop | saat konfigurasi platform berubah |
| `docs/PRIVACY.md` | data lokal, jaringan keluar, izin, hapus data | saat perilaku data berubah |
| `docs/TESTING.md` | command, inventaris test, checklist manual | saat test/CI berubah |
| `docs/KNOWN_ISSUES.md` | keterbatasan & bug yang diketahui | setiap kali menemukan/menyelesaikan isu |
| `docs/WORKFLOW.md` | branch, commit, PR, rilis | saat proses rilis berubah |
| `docs/AUDIT_2026-11.md` | **snapshot historis**, jangan diubah | tidak pernah |

Aturan tunggal: **jika kode berubah, dokumen yang relevan ikut berubah di commit yang sama.**

## 3. Toolchain & Command

Flutter **3.47.1** / Dart **3.13.1** (lihat `.fvmrc`). **Jangan** menaikkan/menurunkan versi SDK
sebagai bagian dari perubahan fitur; itu perubahan tersendiri.

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # jangan pakai `flutter pub run`
fvm flutter analyze
fvm flutter test
make check        # analyze + test + check_docs
make apk          # flutter build apk --debug
```

## 4. Arsitektur & Aturan Layer

```
lib/
├── main.dart              # composition root: engine AI, notifikasi, ObjectBox
├── app.dart               # MaterialApp.router, locale, tap notifikasi
├── core/                  # design system, l10n, router, logger, utils murni
├── models/                # entity ObjectBox + provider service
├── services/              # ai/, database/, mood, notification, stt, tts
└── features/              # layar + controller per fitur
```

Aturan dependensi:

- `core/` **tidak boleh** mengimpor `features/` kecuali: `core/router/app_router.dart`
  (composition root routing), `core/l10n/app_strings.dart` (provider bahasa app-global), dan
  `core/design/` (token/komponen).
- `services/` **tidak boleh** mengimpor widget/`features/`.
- `models/` hanya entity + provider service; tidak ada UI, tidak ada panggilan engine.
- `features/` boleh mengimpor `core/`, `models/`, `services/`.

## 5. Aturan Wajib (Non-Negotiable)

1. **Riverpod manual.** Pakai `Notifier`/`AsyncNotifier`. **Tidak ada** `riverpod_annotation`,
   codegen provider, atau `StateProvider` (tidak diekspos lagi di Riverpod 3).
2. **ObjectBox = source of truth.** Setelah mengubah entity: jalankan build_runner.
   **Jangan** menyunting `lib/objectbox.g.dart` atau `lib/objectbox-model.json` manual.
3. **UI memakai `material_ui`.** Import `package:material_ui/material_ui.dart`;
   jangan mencampur `package:flutter/material.dart` di file yang sama.
   Warna/ukuran/durasi memakai token `AppColors`, `AppSizes`, `AppDurations`, `AppTextStyles`.
4. **String user-facing lewat `AppStrings`** (implementasi ID + EN). Bila belum terlokalisasi,
   catat di `docs/KNOWN_ISSUES.md` — jangan diam-diam menambah hardcode baru.
5. **Panggilan engine AI hanya di** `services/ai/`, `services/tts_service.dart`,
   `services/stt_service.dart`. Widget tidak pernah memanggil engine/plugin AI langsung.
6. **Jaringan hanya untuk**: unduhan model (HuggingFace), unduhan font Google Fonts.
   Chat, memori, persona, dan mood **tidak boleh** dikirim keluar.
7. **Error lewat `AppLogger`.** Tidak ada `print`/`debugPrint` di luar `core/errors/app_logger.dart`.
8. **Test wajib** untuk perilaku baru (fungsi murni/controller/router/DB); `make check` harus
   lulus sebelum PR. Jangan menambah test yang hanya menguji wiring/mock echo.
9. **Dependency** diperiksa ke pub.dev (API + changelog + batasan SDK/platform), pin dihormati,
   `docs/DEPENDENCIES.md` + blok mesinnya ikut diperbarui.
10. **Commit** memakai Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `ci:`);
    branch `feat/*`, `fix/*`, `chore/*`.

## 6. Definition of Done

- Perilaku sesuai spesifikasi `docs/FEATURES.md` (status bukan `Backlog`).
- `fvm flutter analyze` → 0 error, 0 warning.
- `fvm flutter test` → semua lulus.
- `make check` lulus (termasuk `tool/check_docs.dart`).
- `fvm flutter build apk --debug` lulus bila permukaan Android berubah.
- Dokumen yang relevan diperbarui pada commit yang sama; tidak ada klaim fitur yang tidak ada.
- Perubahan entity → binding ObjectBox diregenerasi dan ikut di-commit.

## 7. Eskalasi

Bila kode dan dokumen bertentangan: **perbaiki keduanya** atau catat status sebenarnya di
`docs/KNOWN_ISSUES.md`. Jangan membiarkan klaim palsu, dan jangan menurunkan klaim kode tanpa
jejak. Bila verifikasi tidak mungkin di lingkungan saat ini (iOS/macOS tanpa Xcode, inference
tanpa perangkat), tulis **unverified** secara eksplisit — jangan mengklaim lulus.

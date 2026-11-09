# TESTING — Strategi, Command, dan Checklist

## 1. Command

```bash
make check        # flutter analyze + flutter test + dart run tool/check_docs.dart
make setup        # fvm flutter pub get
make gen          # build_runner (regenerasi ObjectBox)
make analyze
make test
make check-docs
make apk          # flutter build apk --debug
```

Setara tanpa Make: `fvm flutter analyze`, `fvm flutter test`,
`fvm dart run tool/check_docs.dart`, `fvm dart run build_runner build --delete-conflicting-outputs`,
`fvm flutter build apk --debug`.

Test ObjectBox membutuhkan library native di host:

```bash
bash <(curl -s https://raw.githubusercontent.com/objectbox/objectbox-dart/main/install.sh)
OBJECTBOX_LIB_DIR=$PWD fvm flutter test test/core/objectbox_settings_test.dart
```

Tanpa library native, test tersebut **di-skip** (bukan dihapus).

## 2. Inventaris test

| File | Cakupan |
| --- | --- |
| `test/core/app_strings_test.dart` | kelengkapan & konsistensi string ID/EN |
| `test/core/content_safety_test.dart` | gate input/output + redirect |
| `test/core/design_tokens_test.dart` | nilai token warna/ukuran/durasi |
| `test/core/model_catalog_test.dart` | katalog LLM, `modelOptionByFileName`, pemetaan tipe engine, katalog speech |
| `test/core/mood_service_test.dart` | transisi mood & idle time (fake `MoodStore`) |
| `test/core/notification_time_test.dart` | `nextInstanceOf` (hari ini/besok/akhir bulan, `Asia/Jakarta`) |
| `test/core/objectbox_settings_test.dart` | persistensi 7 field `AppSettings` lintas close/reopen |
| `test/core/prompt_builder_test.dart` | system prompt, batas riwayat, ringkasan, instruksi bahasa |
| `test/core/router_guard_test.dart` | matriks `resolveRedirect` (gate & redirect) |
| `test/core/wav_pcm_test.dart` | parser WAV: chunk `LIST`/`JUNK`, padding ganjil, tanpa `data` |
| `test/features/chat/chat_bubble_test.dart` | bubble user/AI, timestamp, tombol speaker |
| `test/features/chat/input_bar_test.dart` | hint, tombol kirim, batas 2000 karakter, mic |
| `test/features/memory/memory_screen_test.dart` | empty state, grouping kategori, pencarian |
| `test/features/onboarding/age_gate_test.dart` | teks ID/EN, tombol confirm/decline |

**Gap yang diketahui** (lihat `KNOWN_ISSUES.md`): tidak ada test untuk `ChatNotifier`
end-to-end (butuh engine), `TtsService`/`SttService` (butuh plugin native), widget notifikasi,
dan `ModelServiceNotifier` (butuh file model).

## 3. Apa yang harus dites saat mengubah sesuatu

| Perubahan | Test minimal |
| --- | --- |
| Fungsi murni (`PromptBuilder`, `resolveRedirect`, `pcmFromWav`, `nextInstanceOf`) | unit test di `test/core/` |
| Controller/state (`ChatNotifier`, `AppSettingsNotifier`) | unit test dengan provider di-override |
| Entity/skema | regen binding + `objectbox_settings_test` (bila field AppSettings) |
| Katalog/string | `model_catalog_test`, `app_strings_test` |
| UI widget | widget test bila ada perilaku (bukan sekadar snapshot) |
| Dependency/API baru | jalankan `make check` + `make apk` bila Android tersentuh |

Jangan menulis test yang hanya menguji wiring, memantulkan mock, atau menghitung panjang list.
Bug yang diperbaiki sebaiknya mendapat regression test (contoh: parser WAV, persistensi settings).

## 4. CI

`.github/workflows/ci.yml` menjalankan pada setiap push/PR:

1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `git diff --exit-code -- lib/objectbox.g.dart lib/objectbox-model.json` (drift generated)
4. `flutter analyze`
5. `flutter test`
6. `dart run tool/check_docs.dart`

CI memakai Flutter 3.47.1 + JDK 17. Test ObjectBox ter-skip di CI (tanpa library native).

## 5. Checklist manual (perangkat Android)

- [ ] Install model default dari layar model (progress berjalan, bisa dibatalkan).
- [ ] Upload file `.litertlm`/`.task` dengan nama kustom → model dikenali setelah restart.
- [ ] Chat streaming: token muncul bertahap, typing indicator hilang di akhir.
- [ ] Gate keamanan: pesan terlarang → deflection tampil, tidak ada jawaban model.
- [ ] STT: rekam → transkrip masuk ke input, terkirim dengan flag voice.
- [ ] TTS: aktifkan di Settings → tombol speaker di bubble; ganti model suara berfungsi.
- [ ] Notifikasi pagi: atur jam, tutup app, verifikasi muncul pada jam lokal perangkat.
- [ ] Tap notifikasi saat app tertutup → langsung ke chat (setelah setup selesai).
- [ ] Dark/light/system theme tanpa warna token yang salah.
- [ ] Memori: fakta baru muncul, edit/hapus berfungsi, `lastReferencedAt` bertambah.
- [ ] Reset persona mengosongkan memori/mood; Reset semua data kembali ke gerbang usia dan
      model tetap terpasang.
- [ ] Rotasi/keluar-masuk layar memory/settings menghentikan audio yang sedang diputar.

iOS, macOS, dan desktop **belum** masuk checklist ini karena belum terverifikasi di lingkungan
Linux tanpa Xcode.

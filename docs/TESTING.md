# TESTING — Strategi, Command, dan Checklist

## 1. Command

```bash
make check        # analyze + test + check-docs + gen-check
make setup        # fvm flutter pub get
make gen          # build_runner (regenerasi ObjectBox)
make gen-check    # regen + git diff binding (deteksi drift)
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

Tanpa library native, test tersebut **di-skip** di mesin lokal (bukan dihapus). Di CI
(`CI=true`) library wajib ada — test **gagal** bila tidak, supaya regresi persistensi tidak lolos
diam-diam.

## 2. Inventaris test

| File | Cakupan |
| --- | --- |
| `test/core/app_strings_test.dart` | tabel kunci baru ID/EN, copy privasi/age gate, daftar notifikasi, plural Inggris |
| `test/core/content_safety_test.dart` | gate input/output, `SafetyRedirect`, kategori `personaBreak` |
| `test/core/design_contrast_test.dart` | kontras token ≥ 4.5:1 di seluruh 8 palet (4 tema × light/dark) |
| `test/core/memory_fact_merger_test.dart` | `mergeFacts`: key case-insensitive, duplikat batch, batas panjang, hapus tertua |
| `test/core/model_catalog_test.dart` | katalog LLM, `modelOptionByFileName`, pemetaan tipe engine, katalog speech |
| `test/core/model_error_test.dart` | `classifyModelError` (404/401/429/cancel/storage/engine/network) |
| `test/core/mood_service_test.dart` | batas kata (remain/crystal), skor user+AI, tie-break, transisi, peluruhan, idle |
| `test/core/notification_time_test.dart` | `nextInstanceOf` (hari ini/besok/akhir bulan, `Asia/Jakarta`) |
| `test/core/objectbox_settings_test.dart` | persistensi **semua** field `AppSettings` + `normalized()` |
| `test/core/prompt_builder_test.dart` | batas karakter prompt, 12 fakta, sanitasi, pesan blokir, `selectMemoryFacts` |
| `test/core/router_guard_test.dart` | matriks `resolveRedirect` (gate, `/privacy`, `/model-download`, `/hub`) |
| `test/core/wav_pcm_test.dart` | parser WAV: chunk `LIST`/`JUNK`, padding ganjil, tanpa `data` |
| `test/features/chat/chat_bubble_test.dart` | kapsul user solid, editorial thread AI, timestamp, speaker, gambar disanitasi |
| `test/features/chat/input_bar_test.dart` | hint, kirim, batas 2000 karakter, counter, tombol stop |
| `test/features/hub/companion_hub_screen_test.dart` | status persona, snapshot memori, tap starter → `/chat` + input terisi |
| `test/features/memory/memory_screen_test.dart` | empty state, grouping kategori, pencarian |
| `test/features/model/model_error_text_test.dart` | setiap `ModelErrorKind` punya pesan ID/EN |
| `test/features/navigation/main_shell_test.dart` | 4-tab `MainShellScaffold` tanpa overflow di 320 dp & sinkron `activeShellTabProvider` |
| `test/features/onboarding/age_gate_test.dart` | teks ID/EN, konfirmasi menyimpan `isAgeVerified`, tautan privasi |
| `test/features/settings/privacy_screen_test.dart` | judul/kebijakan/tombol kembali (ID + EN) |
| `test/features/settings/section_overflow_test.dart` | Appearance (termasuk pilih `themeStyle`)/Language/Model tidak overflow di 320 dp |
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
2. `bash <(curl -s .../objectbox-dart/main/install.sh)` (library native ObjectBox)
3. `dart run build_runner build --delete-conflicting-outputs`
4. `git diff --exit-code -- lib/objectbox.g.dart lib/objectbox-model.json` (drift generated)
5. `flutter analyze`
6. `flutter test` dengan `CI=true` + `OBJECTBOX_LIB_DIR=$GITHUB_WORKSPACE`
7. `dart run tool/check_docs.dart`

CI memakai Flutter 3.47.1 + JDK 17. Test ObjectBox **berjalan** di CI; bila library native hilang,
test gagal (bukan skip). `make check` menjalankan langkah yang sama secara lokal, termasuk
`gen-check`.

## 5. Checklist manual (perangkat Android)

- [ ] Install model default dari layar model (progress berjalan, bisa dibatalkan).
- [ ] Upload file `.litertlm`/`.task` dengan nama kustom → model dikenali setelah restart.
- [ ] Chat streaming: token muncul bertahap, typing indicator hilang di akhir.
- [ ] Stop generation: tekan tombol stop saat AI menjawab → jawaban parsial tersimpan + banner.
- [ ] Ganti model dari Settings → Model AI: model lain terpasang, chat memakai model baru.
- [ ] Gate keamanan: pesan terlarang → deflection tampil, tidak ada jawaban model.
- [ ] STT: rekam → transkrip masuk ke input, terkirim dengan flag voice.
- [ ] TTS: aktifkan di Settings → tombol speaker di bubble; ganti model suara berfungsi.
- [ ] Notifikasi pagi: atur jam, tutup app, verifikasi muncul pada jam lokal perangkat.
- [ ] Check-in: pilih interval 1/3/6/12 jam, matikan layar, verifikasi waktu munculnya.
- [ ] Izin notifikasi ditolak → sakelar menolak aktif + SnackBar panduan.
- [ ] Ekspor chat: dialog simpan OS muncul, file bisa dibuka dari pengelola file.
- [ ] STT izin ditolak → SnackBar dengan aksi "Buka Pengaturan".
- [ ] Tap notifikasi saat app tertutup → langsung ke chat (setelah setup selesai).
- [ ] Dark/light/system theme tanpa warna token yang salah.
- [ ] Memori: fakta baru muncul, edit/hapus berfungsi, `lastReferencedAt` bertambah.
- [ ] Reset persona mengosongkan memori/mood; Reset semua data kembali ke gerbang usia dan
      model tetap terpasang.
- [ ] Rotasi/keluar-masuk layar memory/settings menghentikan audio yang sedang diputar.

iOS, macOS, dan desktop **belum** masuk checklist ini karena belum terverifikasi di lingkungan
Linux tanpa Xcode.

# WORKFLOW — Branch, Commit, PR, Rilis

Aturan kerja lengkap ada di [`../AGENTS.md`](../AGENTS.md). Dokumen ini operasional.

## 1. Branch

| Prefix | Dipakai untuk |
| --- | --- |
| `feat/<ringkas>` | fitur baru |
| `fix/<ringkas>` | perbaikan bug |
| `chore/<ringkas>` | dependency, build, konfigurasi |
| `docs/<ringkas>` | dokumentasi saja |

Branch utama pengembangan: `development`. Jangan menulis langsung ke `main`/`development`.

## 2. Commit

Conventional Commits, satu commit = satu perubahan logis:

```
feat(chat): add memory merge by key
fix(notifications): schedule with device timezone
chore(deps): migrate to flutter_edge_ai and material_ui
docs: overhaul README and add current-state docs
```

Aturan:

- Jangan mencampur perubahan perilaku dengan perubahan dokumentasi yang tidak terkait.
- Perubahan entity + binding generated masuk commit yang sama.
- Sertakan alasan pada commit yang memilih pin versi (`build:`/`chore(deps):`).

## 3. Pemeriksaan sebelum push

```bash
fvm flutter analyze         # 0 error, 0 warning
fvm flutter test            # semua lulus
make check-docs             # docs ↔ pubspec/.fvmrc konsisten
fvm flutter build apk --debug   # bila menyentuh Android/manifest/plugin
```

`make check` menjalankan analyze + test + check-docs sekaligus.

Bila mengubah entity ObjectBox, jalankan `make gen` dan pastikan
`lib/objectbox.g.dart` + `lib/objectbox-model.json` ikut ter-stage (CI memeriksa drift generated).

## 4. Pull Request

Checklist:

- [ ] Deskripsi menjelaskan masalah & solusi, bukan hanya daftar file.
- [ ] `make check` lulus (tempel output ringkas).
- [ ] `make apk` lulus bila Android tersentuh; sebutkan bila tidak dijalankan.
- [ ] Fitur baru/berubah: `docs/FEATURES.md` (status + acceptance) diperbarui.
- [ ] Dependency berubah: `docs/DEPENDENCIES.md` + blok mesin diperbarui.
- [ ] Entity berubah: `docs/DATA_MODEL.md` diperbarui.
- [ ] Keterbatasan baru dicatat di `docs/KNOWN_ISSUES.md`.
- [ ] Tidak ada klaim yang belum diverifikasi (tandai **unverified**).

## 5. Sinkronisasi dokumen

Dokumen dan kode harus bergerak bersama:

| Perubahan kode | Dokumen |
| --- | --- |
| Struktur/provider/routing | `docs/ARCHITECTURE.md` |
| Perilaku fitur | `docs/FEATURES.md` |
| Token/komponen UI | `docs/DESIGN.md` |
| Entity/box | `docs/DATA_MODEL.md` |
| Prompt/model/speech | `docs/AI_PIPELINE.md` |
| Dependency/toolchain | `docs/DEPENDENCIES.md` + `README.md` badge |
| Config platform | `docs/PLATFORM_SETUP.md` |
| Perilaku data/jaringan | `docs/PRIVACY.md` + `README.md` |
| Test/CI | `docs/TESTING.md` |

`tool/check_docs.dart` memverifikasi: keberadaan file wajib, sinkronisasi blok dependency dengan
`pubspec.yaml`/`.fvmrc`, tidak ada `dependency_overrides`/paket lama, link markdown relatif
valid, dan ID FR unik. Jalankan lewat `make check-docs`.

## 6. Rilis

Kondisi saat ini (lihat `KNOWN_ISSUES.md`):

- Application ID masih `com.example.edge_chat`.
- Build release memakai kunci debug.

Karena itu **belum ada rilis produksi**. Sebelum rilis pertama, wajib:

1. Ganti `applicationId`/`namespace` dan bundle identifier iOS/macOS.
2. Buat keystore release + `signingConfig` (jangan commit secret).
3. Jalankan build release di perangkat nyata dan verifikasi unduhan model, chat, STT/TTS,
   notifikasi.
4. Perbarui `CHANGELOG`/versi di `pubspec.yaml` (`version: x.y.z+build`).
5. Tandai status verifikasi platform di `docs/PLATFORM_SETUP.md`.

## 7. Hal yang tidak boleh dilakukan

- `git commit`/`git push` otomatis oleh agent tanpa instruksi eksplisit pengguna.
- Menyunting `lib/objectbox.g.dart` / `lib/objectbox-model.json` manual.
- Menambah `dependency_overrides` untuk menyelesaikan konflik versi.
- Menambah klaim fitur yang belum ada di kode.
- Menghapus/skip test tanpa mencatat alasannya di `docs/KNOWN_ISSUES.md` atau `docs/TESTING.md`.

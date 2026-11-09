# CONTRIBUTING

Terima kasih sudah berkontribusi ke VirtualHeart. Dokumen ini ringkas; aturan lengkap ada di
[`AGENTS.md`](AGENTS.md).

## Sebelum mulai

1. Baca [`AGENTS.md`](AGENTS.md) (aturan otoritatif, layer, Definition of Done).
2. Baca [`docs/WORKFLOW.md`](docs/WORKFLOW.md) (branch, commit, PR) dan
   [`docs/TESTING.md`](docs/TESTING.md) (command & inventaris test).
3. Pakai Flutter **3.47.1** lewat FVM (`fvm flutter --version`).

## Setup

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run          # atau `make apk`
```

Model AI tidak dibundel; unduh dari layar model (butuh internet sekali) atau unggah file
`.litertlm`/`.task` sendiri.

## Selama mengerjakan

- Perbaiki **akar masalah**, bukan gejala; jangan menambah abstraksi/telemetri yang tidak diminta.
- Hormati arsitektur: `core/` tidak mengimpor `features/` (kecuali router/l10n/design),
  `services/` tidak mengimpor widget, panggilan engine AI hanya di `services/`.
- String user-facing lewat `AppStrings` (ID + EN); token desain dari `AppSizes`/`AppColors`/
  `AppDurations`.
- Perubahan entity → regenerate ObjectBox, jangan edit binding manual.

## Sebelum PR

```bash
make check      # analyze + test + check-docs
make apk        # bila menyentuh Android/manifest/plugin
```

Checklist PR:

- [ ] `make check` hijau.
- [ ] Perilaku baru punya test (fungsi murni/controller/router/DB), bukan test wiring.
- [ ] `docs/FEATURES.md` diperbarui bila status fitur berubah.
- [ ] `docs/DEPENDENCIES.md` (+ blok mesin) diperbarui bila dependency berubah.
- [ ] `docs/KNOWN_ISSUES.md` diperbarui untuk keterbatasan baru.
- [ ] Conventional Commits, satu topik per commit.

## Melaporkan bug

Sertakan: versi Flutter, perangkat/OS, model yang dipakai, langkah reproduksi, hasil yang
diharapkan vs aktual, dan log (`AppLogger` hanya mencetak di debug build).

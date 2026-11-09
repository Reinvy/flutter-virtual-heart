# Dokumentasi VirtualHeart

Indeks dokumen **current-state**. Semua dokumen di bawah mencerminkan kode pada branch
`development`; aturan kerja otoritatif ada di [`../AGENTS.md`](../AGENTS.md).

## Dokumen

| Dokumen | Isi | Diperbarui saat |
| --- | --- | --- |
| [`../AGENTS.md`](../AGENTS.md) | aturan kerja, layer, Definition of Done | proses/aturan berubah |
| [`../README.md`](../README.md) | gambaran publik (Inggris), quick start | fitur/platform berubah |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | alur kontribusi & PR checklist | proses kontribusi berubah |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | init flow, tree `lib/`, provider, routing | struktur/komposisi berubah |
| [`FEATURES.md`](FEATURES.md) | spesifikasi + status tiap FR | perilaku fitur berubah |
| [`DESIGN.md`](DESIGN.md) | token, komponen, motion, aksesibilitas | token/komponen berubah |
| [`DEPENDENCIES.md`](DEPENDENCIES.md) | toolchain & paket (+ blok mesin) | dependency berubah |
| [`DATA_MODEL.md`](DATA_MODEL.md) | entity ObjectBox, box, reset flow | entity/skema berubah |
| [`AI_PIPELINE.md`](AI_PIPELINE.md) | katalog model, prompt, memori, mood, speech | pipeline AI berubah |
| [`PLATFORM_SETUP.md`](PLATFORM_SETUP.md) | konfigurasi Android/iOS/macOS/desktop | config platform berubah |
| [`PRIVACY.md`](PRIVACY.md) | data lokal, jaringan keluar, izin | perilaku data berubah |
| [`TESTING.md`](TESTING.md) | command, inventaris test, checklist manual | test/CI berubah |
| [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md) | keterbatasan & bug diketahui | setiap temuan |
| [`WORKFLOW.md`](WORKFLOW.md) | branch, commit, PR, rilis | proses rilis berubah |

## Dokumen historis

[`AUDIT_2026-11.md`](AUDIT_2026-11.md) adalah **snapshot** audit 2026-11-09. Dokumen ini
**tidak diperbarui**; status terkini selalu ada di [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

## Konvensi

- Bahasa dokumen internal: **Indonesia**. `README.md` publik: **Inggris**.
- Nomor baris tidak pernah dikutip; sebut path + nama simbol.
- Klaim status memakai salah satu label: `Implemented`, `Partial`, `Backlog`, `Unverified`.
- Dokumen yang menyebut versi dependency wajib sinkron dengan blok mesin di
  `DEPENDENCIES.md` (`fvm dart run tool/check_docs.dart` memverifikasinya).

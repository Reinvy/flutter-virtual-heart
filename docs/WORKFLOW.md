# WORKFLOW.md — VirtualHeart

Dokumen ini menjelaskan **alur kerja pengembangan** (workflow) yang wajib diikuti oleh
semua developer dan coding agent di project VirtualHeart. Panduan ini dirancang selaras
dengan aturan di `docs/AGENTS.md` dan tidak bergantung pada kode lama.

**Set dokumen fondasi:** `AGENTS.md` (aturan), `DESIGN.md` (desain & arsitektur),
`FEATURES.md` (spesifikasi fitur), dan dokumen ini (alur kerja). Baca semuanya sebelum
memulai pekerjaan.

---

## 1. Strategi Branch

Project menggunakan alur berbasis **trunk-based** yang disederhanakan:

```
main ─────────────────────────────────────── (stabil, hanya dari merge PR)
  └── development ───────────────────────── (integrasi harian)
        ├── feat/fitur-xxx                 (fitur baru)
        ├── fix/bug-xxx                    (perbaikan bug)
        ├── refactor/xxx                   (perubahan struktur)
        └── docs/xxx                       (dokumentasi)
```

### Aturan
| Branch | Sifat | Siapa yang menulis |
|---|---|---|
| `main` | Stabil, siap rilis | Hanya dari merge PR |
| `development` | Integrasi harian | Bebas komit langsung untuk perubahan kecil |
| `feat/*`, `fix/*`, dst. | Sementara utk satu unit kerja | Bebas |

- **Perubahan kecil/dokumentasi:** boleh komit langsung ke `development`.
- **Fitur/perubahan besar atau arsitektural:** wajib lewat branch fitur + PR.
- **Hanya `main`** menerima kode yang sudah direview & lolos.

---

## 2. Alur Pengembangan Sebuah Fitur

Ikuti langkah berikut untuk setiap fitur dari `docs/FEATURES.md`:

1. **Pilih task** dari daftar fitur / backlog (`docs/FEATURES.md`).
2. **Baca dokumen terkait** — `AGENTS.md`, `FEATURES.md`, `DESIGN.md` untuk spesifikasi
   & aturan desain.
3. **Buat branch** dari `development`:
   ```bash
   git checkout development
   git pull
   git checkout -b feat/nama-fitur
   ```
4. **Implementasi** mengikuti struktur `lib/features/<fitur>/` (UI + controller + state);
   semua nilai UI memakai design tokens dari `core/design/` (lihat `DESIGN.md`).
5. **Tulis test** untuk logic & widget utama.
6. **Verifikasi lokal**:
   ```bash
   flutter analyze            # wajib: 0 error
   flutter test               # wajib: semua pass
   flutter pub run build_runner build --delete-conflicting-outputs   # bila perlu
   ```
7. **Komit secara atomik** (pesan `type(scope): deskripsi`).
8. **Push & buka PR** ke `development` (atau `main` untuk rilis).
9. **Review** oleh developer lain (atau self-review bila solo).
10. **Merge** setelah lolos semua pemeriksaan.

---

## 3. Siklus Komit & Pesan

Pesan komit mengikuti **Conventional Commits** (lihat `AGENTS.md` §4).

### Batching commit
- Satu komit = satu tanggung jawab logis.
- Jangan mencampur `feat` dan `fix` dalam satu komit.
- Dokumentasi bisa digabung bila sangat kecil, tetapi lebih baik `docs:` terpisah.

### Contoh yang baik
```
feat(chat): tambah streaming respon AI
fix(memory): perbaiki ekstraksi dob pada langsung ke kategori tanggal penting
refactor(router): pisahkan guard setup dari definisi rute
docs(features): perbarui prioritas fitur notifikasi
```

---

## 4. Golden Path vs Edge Cases

Ketika mengerjakan fitur, selalu bedakan dua jalur:

### Golden path (jalur ideal)
Alur yang paling umum & diharapkan — harus berjalan mulus dan diuji penuh:
- Onboarding → set persona → model siap → chat → respon AI tampil.
- Untuk tiap fitur, tulis test yang melindungi jalur ini.

### Edge cases (kasus tepi)
Skenario tak terduga yang tetap harus ditangani dengan gagal-gracefully:
- Model belum diunduh / gagal diinisialisasi.
- Koneksi TTS/STT tidak tersedia atau permission ditolak.
- Input pengguna melewati content safety gate.
- Database belum siap atau korup.
- String kosong / terlalu panjang dari pengguna.

> Setiap edge case penting harus **tertangani** (fallback yang jelas, bukan crash).
> Dokumentasikan di `FEATURES.md` bila mengubah perilaku.

---

## 5. Alur Handling Bug

1. **Reproduksi** — buat langkah reproduksi yang jelas.
2. **Isolasi** — tentukan lapisan (UI / controller / service / data).
3. **Tulis test yang gagal** mencerminkan bug (sebaiknya sebelum perbaikan).
4. **Perbaiki** dengan perubahan terkecil & tepat.
5. **Pastikan test pass** dan tidak ada regresi (`flutter test`).
6. **Cek `flutter analyze` bersih.**
7. **Komit** `fix(scope): deskripsi`, push branch `fix/...`, buka PR.

---

## 6. QA & Quality Gate

Sebelum setiap merge, pemeriksaan otomatis minimum:

- [ ] `flutter analyze` → 0 error, 0 warning.
- [ ] `flutter test` → semua test pass.
- [ ] Tidak ada `TODO`/`FIXME` yang ditinggalkan tanpa keterangan.
- [ ] Tidak ada `print`/`debugPrint` di kode produksi.
- [ ] Semua string UI menggunakan konstanta/resource (i18n, `core/l10n/`).
- [ ] Semua warna/spacing/radius/durasi memakai design tokens `core/design/`.
- [ ] Perubahan mengikuti struktur feature-first (`lib/features/`).

> Bila gagal salah satu, **jangan merge**. Perbaiki lalu ulangi.

---

## 7. Rilis (Release)

Untuk setiap rilis ke `main`:

1. Pastikan fitur lengkap & semua test hijau pada `development`.
2. Buat PR `development → main`.
3. Review akhir & merge.
4. Tag versi (semver) sesuai `version:` di `pubspec.yaml`.
5. Tulis catatan rilis ringkas (fitur baru, perbaikan, catatan model).

---

## 8. Kolaborasi & Review

- **Solo developer:** lakukan "self-review" — komit dengan jarak waktu, baca ulang diff
  sebelum merge, dan jangan merge karya sendiri di hari yang sama jika memungkinkan.
- **Reviewer:** periksa kepatuhan terhadap `AGENTS.md` (arsitektur, penamaan, kualitas).
- Setiap orang **bertanggung jawab** menjaga `docs/` tetap sinkron dengan kode.

---

## 9. Definisi Selesai

Sebuah tugas dianggap selesai hanya jika **semua** kondisi di `AGENTS.md` §7 terpenuhi
serta seluruh *quality gate* di atas sudah lolos.
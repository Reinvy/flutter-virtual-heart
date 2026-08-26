# AGENTS.md — VirtualHeart

Dokumen ini adalah **kontrak kerja** untuk semua coding agent, AI, dan developer yang
bekerja di project **VirtualHeart**. Semua pekerjaan di codebase wajib mengikuti aturan
ini. Dokumen disusun sepenuhnya baru sebagai fondasi refactor total — bukan dokumentasi
dari kode lama.

**Set dokumen fondasi (wajib dibaca bersama):**

| Dokumen | Isi |
|---|---|
| `docs/AGENTS.md` | Aturan kerja & arsitektur target (dokumen ini) |
| `docs/DESIGN.md` | Design system, UX, arsitektur target |
| `docs/FEATURES.md` | Spesifikasi fitur (FR-XX) & prioritas |
| `docs/WORKFLOW.md` | Alur kerja pengembangan |

> **Sumber kebenaran:** daftar fitur resmi ada di `docs/FEATURES.md`; semua keputusan
> visual wajib mengikuti `docs/DESIGN.md`. Jika spesifikasi di dokumen ini bertentangan
> dengan `DESIGN.md`/`FEATURES.md`, ikuti yang lebih spesifik dan laporkan
> ketidakkonsistenannya.

---

## 1. Identitas Project

- **Nama:** VirtualHeart
- **Deskripsi:** Aplikasi romantic companion AI yang berjalan **100% on-device**
  (Small Language Model / SLM). Tidak ada data yang dikirim ke server eksternal.
- **Platform target (prioritas):** Android, iOS
- **Lainnya (eksperimental):** macOS, Linux, Windows, Web
- **Fokus:** Privasi penuh, personalisasi mendalam, pengalaman emosional, tanpa akun.

> **Prinsip utama:** Semua inferensi AI, memori, dan data pengguna berjalan dan tersimpan
> lokal di perangkat. Privasi adalah fitur non-negosiasi.

---

## 2. Tumpukan Teknologi (Tech Stack)

| Lapisan | Teknologi |
|---|---|
| Framework | Flutter / Dart |
| State management | Riverpod (`AsyncNotifierProvider`) + code generation |
| Navigasi | go_router dengan route guards |
| Database lokal | ObjectBox (embedded NoSQL) |
| Model AI on-device | flutter_gemma (MediaPipe `.task` + LiteRT-LM `.litertlm`) |
| Text-to-Speech | flutter_gemma_speech (LiteRT C API) + flutter_pcm_sound |
| Speech-to-Text | flutter_gemma_speech (moonshine) + record |
| Notifikasi lokal | flutter_local_notifications + timezone |
| Font | Shippori Mincho (heading) + Nunito (body) |
| Ikon | Material Icons + flutter_svg (ikon sakura) |
| Animasi | flutter_animate + Lottie |
| Code generation | build_runner |

---

## 3. Arsitektur Target

Project menggunakan pendekatan **feature-first modular**. Kode diorganisasi per **fitur**,
bukan per lapisan murni.

```text
lib/
├── main.dart                    # Entry point — init AI engine & database
├── app.dart                    # Root widget — MaterialApp, Riverpod, GoRouter
├── core/                       # Shared lintas fitur (bebas dependensi fitur)
│   ├── design/                 # Design tokens, tema, komponen UI shared
│   ├── router/                 # Definisi rute & guards
│   ├── errors/                 # Penanganan error terpusat
│   ├── l10n/                   # Lokalisasi (ID/EN), string resources
│   └── utils/                  # Helper & ekstensi
│
├── features/                   # Setiap fitur adalah modul mandiri
│   ├── onboarding/             # FR-01, FR-02 (age gate + intro)
│   ├── persona/                # FR-03, FR-10 (setup & profil)
│   ├── model/                  # FR-04 (install model AI)
│   ├── chat/                   # FR-05 s/d FR-10
│   ├── memory/                 # FR-11, FR-12
│   ├── notifications/          # FR-15 s/d FR-17
│   └── settings/               # FR-18 s/d FR-20
│
├── services/                   # Engine lintas fitur (bebas dari widget)
│   ├── ai/                     # Prompt builder, memory extractor, content safety
│   ├── database/               # ObjectBox service
│   ├── tts_service.dart        # FR-07
│   └── stt_service.dart        # FR-06
│
└── models/                     # Entity data (ObjectBox)
```

**Struktur internal satu fitur** (`features/chat/` sebagai contoh):

```text
features/chat/
├── chat_screen.dart        # UI utama
├── widgets/                # Widget khusus fitur
├── chat_controller.dart    # Riverpod Notifier khusus fitur
└── chat_models.dart        # State khusus fitur (jika ada)
```

> Setiap fitur Wajib memisahkan **UI**, **controller (logic)**, dan **state**. Jangan
> mencampur logika bisnis ke dalam widget.

---

## 4. Aturan Penamaan

### File & Folder
- **File Dart:** `snake_case.dart` (contoh: `chat_controller.dart`, `app_theme.dart`)
- **Folder fitur:** `snake_case` (contoh: `features/chat`)

### Kode
| Entitas | Konvensi | Contoh |
|---|---|---|
| Widget / Screen | `PascalCase` | `ChatScreen`, `PersonaSetupScreen` |
| Controller / Notifier | `PascalCase` berakhiran `Controller` | `ChatController` |
| Variable / fungsi | `camelCase` | `lastMessage`, `sendMessage()` |
| Konstanta | `UPPER_SNAKE_CASE` | `kPrimaryColor`, `kSpacingMd` |
| Private | diawali `_` | `_buildBubble()` |
| Enum | `PascalCase`, nilai `camelCase` | `MoodType.happy` |

### Komit (git)
Gunakan **Conventional Commits**:
- `feat:` — fitur baru
- `fix:` — perbaikan bug
- `refactor:` — perubahan struktur tanpa ubah perilaku
- `docs:` — dokumentasi saja
- `test:` — menambah/memperbaiki test
- `chore:` — tugas pemeliharaan (dependency, config)
- `perf:` — optimasi performa
- `style:` — format/whitespace, tidak mengubah logika

Format: `type(scope): deskripsi singkat` — contoh: `feat(chat): tambah typing indicator`.

---

## 5. Standar Kode & Praktik

### Wajib
1. **State via Riverpod** — `Notifier`/`AsyncNotifier`. Dilarang menaruh logika bisnis
   dalam widget atau lewat `setState` jika tidak mutlak diperlukan.
2. **Code generation** — gunakan `riverpod_annotation`; jalankan `build_runner` setelah
   menambah/mengubah notifier ber-annotation.
3. **Widget tetap murni (presentational)** — terima data lewat parameter/props, jangan
   panggil provider langsung dari dalam widget tree jika bisa dibatasi di atas.
4. **Penanganan error terpusat** — gunakan helper di `core/errors/`. Jangan `print`/
   `debugPrint` sembarangan; gunakan pencatat terstruktur.
5. **Konstanta, bukan magic value** — warna, spacing, radius ambil dari design tokens.
6. **Test tiap fitur** — setiap fitur baru harus punya minimal test unit/widget.
7. **Jalankan `flutter analyze`** sebelum commit; pastikan **0 error**.
8. **Commits kecil & atomik** — satu komit satu tanggung jawab.

### Larangan
- ❌ Menaruh LLM/engine calls langsung di widget.
- ❌ Hardcode string panjang di dalam widget (pakai konstanta/resource).
- ❌ Menggunakan package baru tanpa persetujuan (tulis di `pubspec.yaml` + dokumen ini).
- ❌ Mengirim data pengguna ke jaringan — **privacy-first**.
- ❌ Menambahkan dependensi yang membutuhkan internet wajib.

---

## 6. Checklist Menambahkan Fitur Baru

1. **[ ]** Baca `docs/FEATURES.md` dan `docs/DESIGN.md` — ikuti spesifikasi & token design.
2. **[ ]** Pastikan fitur sudah punya ID FR di `docs/FEATURES.md` (tambahkan bila belum).
3. **[ ]** Buat direktori `features/<nama>` dengan struktur UI + controller + state.
4. **[ ]** Daftarkan rute di `core/router/` beserta guard yang sesuai.
5. **[ ]** Tambahkan penyimpanan lokal bila perlu (model ObjectBox di `models/` + service).
6. **[ ]** Gunakan design tokens dari `core/design/`, bukan nilai hardcode.
7. **[ ]** Tulis test unit/widget untuk logic & widget utama fitur.
8. **[ ]** Jalankan `flutter analyze` → 0 error, 0 warning.
9. **[ ]** Jalankan `build_runner` bila ada notifier/entity baru.
10. **[ ]** Komit dengan pesan Conventional Commits yang jelas.
11. **[ ]** Perbarui `docs/FEATURES.md` bila ada perubahan spesifikasi.

---

## 7. Definisi "Selesai" (Definition of Done)

Sebuah tugas dikatakan selesai **hanya jika** semuanya terpenuhi:

- [ ] Kode mengikuti arsitektur feature-first (disiapkan di `lib/features/`).
- [ ] `flutter analyze` bersih (0 error).
- [ ] Test yang relevan sudah ditulis dan **pass**.
- [ ] Tidak ada data yang bocor ke server / tidak ada dependency internet yang tak perlu.
- [ ] Semua nilai UI memakai design tokens dari `core/design/`.
- [ ] Dokumentasi terkait diperbarui (`docs/`).
- [ ] Komit menggunakan Conventional Commits (`type(scope): ...`).

---

## 8. Peran Project

Repo ini dikelola oleh tim kecil/solo. Karena itu:

- **Berkomitmenlah ke `development`** untuk pekerjaan sehari-hari.
- **Hanya merge ke `main`** dari PR yang sudah direview & lolos.
- Perubahan besar/arsitektural harus melalui PR dan diskusi, bukan commit langsung.
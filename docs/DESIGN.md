# DESIGN.md — VirtualHeart

Dokumen ini adalah **sumber kebenaran desain** untuk VirtualHeart: design system (tokens,
komponen, motion), prinsip UX & aksesibilitas, serta arsitektur target hasil refactor.

> **Tema visual: "Sakura Romance"** — terinspirasi Yae Miko & estetika Inazuma
> (Genshin Impact): pink sakura, putih hangat, aksen ungu elektrik (Electro),
> tipografi serif Jepang, dan partikel kelopak sakura.

Dokumen ini **wajib dibaca** bersama:
- `docs/AGENTS.md` — aturan kerja agent/developer
- `docs/FEATURES.md` — spesifikasi fitur
- `docs/WORKFLOW.md` — alur kerja pengembangan

---

## 1. Filosofi Desain

**"Romantic, Warm, Intimate."**

VirtualHeart adalah aplikasi companionship — pengguna datang untuk merasa **ditemani,
dipahami, dan dihargai**. Setiap keputusan desain harus mendukung perasaan itu:

1. **Hangat, bukan mencolok.** Warna hangat, tipografi lembut, ruang bernapas. Hindari
   UI yang ramai, tajam, atau "korporat".
2. **Intim, bukan invasif.** Desain yang terasa personal: pesan yang dekat, notifikasi
   yang seperti dikirim kekasih, animasi yang halus.
3. **Romantis, bukan berlebihan.** Estetika serif + aksen hati yang elegan. Jangan
   menumpuk dekorasi; setiap elemen visual harus punya tujuan emosional.
4. **Privasi adalah ketenangan.** Tidak ada ikon "cloud", tidak ada janji sinkronisasi.
   UI harus menenangkan: semua terjadi di perangkat pengguna.

> **Tema default: Light mode (*Sakura Light*).** Aplikasi pertama kali dibuka dalam
> tema terang — latar blush sakura, permukaan bersih, aksen rose pink + ungu elektrik.
> Dark mode tetap tersedia sebagai pilihan pengguna (FR-18), disetel **independen**
> (bukan inversi): surface lebih terang dari latar, aksen turun chroma.

> Prinsip uji: **"Apakah elemen ini membuat pengguna merasa lebih ditemani?"** Jika tidak,
> sederhanakan.

---

## 2. Design Tokens

Semua nilai visual **wajib** berasal dari tokens di `core/design/`. Dilarang hardcode
warna, radius, spacing, atau durasi di widget.

### 2.1 Warna (Color) — Palet "Sakura Miko"

Diturunkan dari Yae Miko: rambut sakura pink, kimono putih hangat, mata pink,
aksesori ungu elektrik (Electro). Kroma dijaga (prinsip OKLCH); netral di-tint pink.

**Mode utama & default: *Sakura Light*** — kolom Light pada tabel di bawah adalah
**tema default aplikasi**. Dark mode menyusul sebagai opsi pengguna.

| Token | Nilai (Light — *default*) | Nilai (Dark) | Penggunaan |
|---|---|---|---|
| `colorBackground` | `#FDF4F7` (blush sakura) | `#120D14` | Latar utama layar |
| `colorSurface` | `#FFFFFF` (bersih) | `#1D1420` | Kartu, sheet, bar input |
| `colorSurfaceElevated` | `#FBE7EF` (rose muda) | `#2A1B26` | Elemen di atas surface |
| `colorPrimary` (Sakura Pink) | `#C24D7E` | `#F28CB0` | Aksi utama, brand |
| `colorPrimaryDeep` | `#9E3A63` | `#F8A9C6` | **Teks kecil/heading** di light (kontras ≥ 4.5:1) |
| `colorPrimarySoft` | `#F8DCE7` | `#47223A` | Chip, badge, highlight lembut |
| `colorSecondary` (Electro Purple) | `#6D4FA8` | `#B79BE0` | Elemen sekunder, aksen fox/Electro |
| `colorSecondarySoft` | `#EFE6FA` | `#352652` | Background sekunder lembut |
| `colorAccent` (Heart Red) | `#E8546E` | `#F4778C` | Notifikasi, momen penting, hati |
| `colorGold` | `#C9A227` | `#E8C766` | Sparkle, aksen dekoratif |
| `colorTextPrimary` | `#241021` | `#F7EFF5` | Teks utama |
| `colorTextSecondary` | `#6E5466` | `#C4AEC0` | Teks pendukung, label |
| `colorTextOnPrimary` | `#FFFFFF` | `#2A0E1E` | Teks di atas primary |
| `colorDivider` | `#F2E1EA` | `#382639` | Pemisah, border halus |
| `colorSuccess` / `warning` / `error` | `#3E7C4F` / `#9C6F1E` / `#C03948` | `#7BC67E` / `#E5B567` / `#EE6B77` | Status |

> Kontras: teks kecil di light memakai `primaryDeep`; `primary` hanya untuk fill tombol
> (teks putih) dan ikon/grafis besar (≥ 3:1). Semua `ColorScheme` slot terisi — tidak
> ada turunan default Material 3 yang bocor ke kontrol (SegmentedButton, Switch, Chip).

#### 2.1.1 Karakter Sakura Light (tema default)

- **Latar** blush sakura hangat `#FDF4F7` — bukan putih polos.
- **Permukaan** putih `#FFFFFF`; surface terangkat & chip memakai rose muda
  (`#FBE7EF` / `#F8DCE7`).
- **Aksen** sakura pink `#C24D7E` (kasih sayang); ungu elektrik `#6D4FA8`
  (kedalaman, misteri); heart red `#E8546E` hanya untuk momen emosional.
- **Gradient khas**: splash & logo — rose muda → putih → lavender lembut
  (`#F8DCE7 → #FFFFFF → #EFE6FA`), bukan gradient pekat.

### 2.2 Tipografi (Typography)

| Token | Font | Ukuran | Weight | Penggunaan |
|---|---|---|---|---|
| `textDisplay` | Shippori Mincho | 28–32 | Bold | Judul halaman onboarding/persona |
| `textHeadline` | Shippori Mincho | 20–24 | SemiBold | Judul section, nama persona |
| `textTitle` | Shippori Mincho | 16–18 | SemiBold | Judul kartu, sheet profil |
| `textBody` | Nunito | 14–15 | Regular | Teks percakapan, isi settings |
| `textBodyStrong` | Nunito | 14–15 | SemiBold | Poin penting |
| `textCaption` | Nunito | 11–12 | Regular | Label, timestamp, metadata |
| `textButton` | Nunito | 14 | SemiBold | Label tombol |

Aturan:
- **Shippori Mincho** (serif Jepang elegan — identitas sakura/Inazuma) **hanya** untuk
  heading & nama — tidak untuk body panjang.
- Baris percakapan (chat) menggunakan Nunito; markdown tetap dirender (`gpt_markdown`).
- Body min 13–14 untuk UI; tidak ada teks di bawah 11.
- Skala teks mengikuti system (Dynamic Type) — jangan `textScaleFactor` hardcode.

### 2.3 Spacing (Spacing Scale)

| Token | Nilai | Penggunaan |
|---|---|---|
| `spaceXxs` | 4 | Jarak antar ikon & label dalam chip |
| `spaceXs` | 8 | Jarak antar elemen kecil |
| `spaceSm` | 12 | Padding internal kartu kecil |
| `spaceMd` | 16 | Padding standar layar |
| `spaceLg` | 24 | Jarak antar section |
| `spaceXl` | 32 | Jarak antar blok besar |
| `spaceXxl` | 48 | Padding halaman onboarding |

### 2.4 Radius (Corner Radius)

| Token | Nilai | Penggunaan |
|---|---|---|
| `radiusSm` | 8 | Input, chip kecil |
| `radiusMd` | 16 | Kartu, chat bubble |
| `radiusLg` | 24 | Sheet, dialog |
| `radiusFull` | 999 | Avatar, tombol ikon |

> Karakter desain: **rounded & lembut** — hindari sudut tajam (kecuali ikon sistem).
> Tombol utama (PrimaryButton) berbentuk **pill** (konsisten dengan tema).

### 2.5 Elevasi & Bayangan (Elevation)

| Token | Nilai | Penggunaan |
|---|---|---|
| `elevationNone` | 0 | Permukaan datar (default) |
| `elevationSm` | 2 (opacity 0.08) | Kartu pada background |
| `elevationMd` | 8 (opacity 0.12) | Input bar, sheet |
| `elevationLg` | 16 (opacity 0.16) | Dialog, bottom sheet aktif |

> Di dark mode, elevasi diekspresikan dengan kecerahan surface, bukan bayangan keras.

### 2.6 Motion (Durasi & Easing)

| Token | Nilai | Penggunaan |
|---|---|---|
| `durationFast` | 120 ms | Hover, state toggle, chip |
| `durationNormal` | 240 ms | Transisi antar layar, sheet |
| `durationSlow` | 400 ms | Elemen hero, onboarding |
| `curveStandard` | `easeOutCubic` | Sebagian besar animasi |
| `curveEmotive` | `easeInOutBack` (halus) | Heartbeat, bounce lembut |

---

## 3. Komponen UI

Komponen dibangun di `core/design/components/` (shared) dan `features/<fitur>/widgets/`
(khusus fitur). Semua komponen **wajib** memakai tokens §2.

### 3.1 Tombol (Buttons)

| Komponen | Spesifikasi | Penggunaan |
|---|---|---|
| `PrimaryButton` | Fill `colorPrimary`, radius **pill**, tinggi 52, label `textButton` | Aksi utama (Kirim, Lanjutkan) |
| `SecondaryButton` | Outline/tonal `colorSecondary`, tinggi 52 | Aksi sekunder (Batal, Lewati) |
| `GhostButton` | Tanpa fill, teks primary | Aksi tersier (Lewati, Lihat semua) |
| `AppIconButton` | **48×48**, radius `radiusFull` | Mikrofon, play/stop TTS, back, close |

- Minimum target sentuh: **48×48 dp** (termasuk padding) — token `AppSizes.touchTarget`.
- Tombol destruktif (hapus data) selalu `colorError` + dialog konfirmasi.

### 3.2 Input (Text Field & Voice)

- `TextField` standar dengan label, fill `colorSurface`, radius `radiusSm`.
- **Chat input bar**: `colorSurface` + border atas `outlineVariant`, tinggi 56,
  field pill `surfaceContainerHigh`; tombol mikrofon di kiri, tombol kirim (berubah
  jadi stop saat AI merespons) di kanan — keduanya 48×48.
- Status merekam: indikator kecil + animasi waveform (STT aktif).

### 3.3 Chat Bubble

| Elemen | Spesifikasi |
|---|---|
| Bubble user | Align kanan, fill `primary`, teks `onPrimary` |
| Bubble assistant | Align kiri, fill `surfaceContainerLow`, teks `onSurface` |
| Radius | `radiusMd` dengan sudut kecil mengarah ke pengirim |
| Timestamp | `textCaption`, `colorTextSecondary`, di bawah bubble |
| Max width | 75% lebar layar |

- **Typing indicator**: 3 titik animasi (`primaryDeep`), bubble `surfaceContainerLow`,
  avatar placeholder gradien rose.
- **Mood chip** di atas bubble assistant: label mood + ikon (lihat §3.4).

### 3.4 Mood Indicator

- Chip kecil (tinggi 28) dengan ikon + label mood.
- Warna mood (dioptimalkan untuk **Sakura Light**): Happy `primaryDeep`, Longing
  `secondary`, Playful `#D4739D` (rose muda), Sad `secondarySoft` dengan teks
  `secondary` gelap, Excited `accent`.
- Muncul di header chat dan di atas bubble assistant. Perubahan mood dianimasikan
  dengan fade + scale kecil (`durationNormal`).

### 3.5 Persona Profile Sheet

- Bottom sheet `radiusLg` atas, drag handle (theme `bottomSheetTheme`).
- Konten: nama (Shippori `textTitle`), gender, mood saat ini + intensitas bar,
  hobi sebagai chip, preset kepribadian + deskripsi, tombol "Edit Persona".
- Bisa di-swipe up dari chat (tap avatar/title di AppBar).

### 3.6 Kartu (Cards)

- `colorSurface`, `elevationSm`, radius `radiusMd`, padding `spaceMd`.
- Digunakan di: settings sections (`SectionCard`), kartu memory, ringkasan hari.

### 3.7 Empty States

- `EmptyState` component shared: ikon dalam lingkaran soft + judul + body + aksi opsional.
- Contoh: chat kosong → avatar persona + sapa hangat; memory kosong →
  "Belum ada kenangan — bicaralah denganku lebih sering."

### 3.8 Dialog & Konfirmasi

- `showConfirmDialog` component shared (title, body, confirm/cancel label,
  destructive = `colorError`).
- Setiap aksi penghapusan data **wajib** konfirmasi eksplisit.

### 3.9 Latar & Dekorasi

- `SakuraBackground`: partikel kelopak sakura (CustomPainter, tanpa aset raster),
  menghormati `MediaQuery.disableAnimations` (statis) & dikecualikan dari semantics.
- `SakuraDivider`: pemisah dengan aksen hati di tengah.
- `assets/icons/sakura.svg`: ikon kelopak sakura (SVG, `currentColor`) — dipakai di
  onboarding, header persona, empty states.

### 3.10 Notifikasi

- Konten ditulis hangat, seolah dari persona (nama persona di title).
- Ikon channel: morning (🌅), check-in (💬), special day (🎂/❤️).
- Tapping notifikasi membuka app langsung ke chat.

---

## 4. Motion & Micro-interactions

Prinsip: **animasi memperkuat emosi, bukan memamerkan teknologi.**

| Momen | Animasi | Token |
|---|---|---|
| Transisi antar layar | Fade + slide halus (16 px) | `durationNormal`, `curveStandard` |
| Kirim pesan | Bubble muncul dengan scale 0.95→1 + fade | `durationFast` |
| AI mulai mengetik | Typing indicator bounce | `durationNormal` |
| Token streaming | Teks muncul bertahap (tanpa animasi per-karakter yang mengganggu) | — |
| Perubahan mood | Chip fade + scale | `durationNormal` |
| Heartbeat (splash/logo) | Scale 1→1.08→1 berulang | `durationSlow`, `curveEmotive` |
| Bottom sheet | Slide up + backdrop fade | `durationNormal` |
| Suka/hati pada pesan | Pop kecil + burst partikel (jarang, hemat) | `durationFast` |

Aturan:
- **Jangan animasikan konten teks yang sedang dibaca** (hindari per-karakter typing
  yang berlebihan).
- Gunakan `flutter_animate` untuk transisi umum.
- **Hormati `MediaQuery.disableAnimations`** — kurangi/hentikan animasi bila sistem
  memintanya (splash, sparkle, kelopak, heartbeat).

---

## 5. UX & Aksesibilitas

### 5.1 Prinsip UX

1. **Golden path dulu.** Alur utama (persona → chat → balasan) harus mulus & cepat;
   edge case ditangani dengan fallback yang jelas (`WORKFLOW.md` §4).
2. **Satu layar, satu fokus.** Hindari layar yang meminta banyak keputusan sekaligus.
3. **Umpan balik instan.** Setiap aksi memberi respons visual dalam 120 ms.
4. **Bahasa yang hangat.** Label, tombol, dan pesan error ditulis hangat & manusiawi,
   bukan teknis ("Maaf, aku belum bisa menjawab itu" > "Error 500").
5. **Konfirmasi destruktif.** Hapus riwayat / wipe memory selalu pakai dialog
   konfirmasi + konsekuensi yang jelas.

### 5.2 Aksesibilitas

- **Kontras**: teks normal ≥ 4.5:1, teks besar ≥ 3:1 terhadap background (uji token
  warna dark & light). Teks kecil di light memakai `primaryDeep`.
- **Target sentuh** minimal 48×48 dp (`AppSizes.touchTarget`).
- **Dynamic Type**: gunakan `textScaler` default; jangan hardcode ukuran teks absolut.
- **Screen reader**: semua ikon punya `Semantics.label`; chat bubble dibaca sebagai
  "Pesan dari <nama persona>: <isi>"; tombol mikrofon punya label "Rekam suara".
- **Reduced motion**: hormati `MediaQuery.disableAnimations`.
- **Mode terang/gelap**: semua layar wajib diuji di kedua mode, tetapi **dioptimalkan
  untuk light** (tema default). Kontras dihitung terhadap latar Sakura Light.

---

## 6. Arsitektur Target

Arsitektur hasil refactor mengikuti **feature-first modular** — kode diorganisasi per
fitur, bukan per lapisan murni. Struktur ini **wajib** diikuti semua kode baru.

```text
lib/
├── main.dart                    # Entry point — init AI engine & database
├── app.dart                     # Root widget — MaterialApp, Riverpod, GoRouter
│
├── core/                        # Shared lintas fitur — BEBAS dependensi fitur
│   ├── design/                  # Design tokens, tema, komponen UI shared
│   │   ├── tokens/              # app_colors, app_sizes, app_durations, text_styles
│   │   ├── app_theme.dart       # Light/Dark ThemeData (Material 3 lengkap)
│   │   └── components/          # PrimaryButton, SectionCard, SakuraBackground,
│   │                            # SakuraDivider, ConfirmDialog, EmptyState,
│   │                            # AppIconButton, SpeakerButton
│   ├── router/                  # Definisi rute & guards
│   ├── errors/                  # Penanganan error terpusat (exception mapper, logger)
│   ├── utils/                   # Helper & ekstensi (date_formatter, dst.)
│   └── l10n/                    # Localization (ID/EN), string resources
│
├── features/                    # Setiap fitur = modul mandiri
│   ├── onboarding/              # FR-02
│   ├── persona/                 # FR-03, FR-10
│   ├── model/                   # FR-04 (model install)
│   ├── chat/                    # FR-05 s/d FR-10
│   ├── memory/                  # FR-11, FR-12
│   ├── notifications/           # FR-15 s/d FR-17
│   └── settings/                # FR-18 s/d FR-20
│
├── services/                    # Engine lintas fitur — bebas dari widget
│   ├── ai/                      # Prompt builder, memory extractor, content safety
│   ├── database/                # ObjectBox service (boxes, repositori)
│   ├── tts_service.dart         # FR-07
│   └── stt_service.dart         # FR-06
│
└── models/                      # Entity data (ObjectBox): Message, MemoryFact,
                                 # MoodState, PersonaConfig, AppSettings
```

### 6.1 Struktur internal satu fitur

```text
features/chat/
├── chat_screen.dart         # UI utama (presentational)
├── widgets/                 # Widget khusus fitur (chat_bubble, input_bar, ...)
├── chat_controller.dart     # Riverpod Notifier/AsyncNotifier khusus fitur
└── chat_models.dart         # State khusus fitur (jika ada)
```

### 6.2 Aturan dependensi

1. **Arah dependensi satu arah**: `features` → `core` → (Flutter/Dart). `core` **tidak
   boleh** mengimpor `features`.
2. `services` & `models` boleh diimpor oleh `features` dan `core` (bukan sebaliknya
   dari `core` ke UI).
3. Widget **presentational**: terima data lewat parameter; logika bisnis & state
   tinggal di controller/notifier.
4. **Satu sumber kebenaran desain** ada di `core/design/` — fitur tidak boleh
   mendefinisikan warna/spacing sendiri.
5. **Error handling terpusat** di `core/errors/` — fitur melempar/me-mapping error ke
   tipe domain, UI menampilkan pesan hangat.

### 6.3 State management

- Semua state memakai **Riverpod** (`Notifier`/`AsyncNotifier` + `riverpod_annotation`).
- Provider global (objectbox, theme, settings, mood) di `core/` atau `app` level;
  provider fitur di dalam `features/<fitur>/`.
- Dilarang `setState` untuk logika bisnis; `setState` hanya untuk animasi/UI murni.

---

## 7. Alur Navigasi Target

```text
Splash
  │
  ▼
Age Gate (13+) ──────────────► (ditolak) Exit
  │
  ▼
Onboarding (3 halaman)
  │
  ▼
Persona Setup
  │
  ▼
Model Install ───────────────► (gagal) Layar retry + panduan storage
  │
  ▼
Chat (home) ──► Memory (AppBar)
     │
     └──► Settings (AppBar)
```

- **GoRouter** + **route guards**: setiap rute memeriksa prasyarat (age gate, persona,
  model siap). Belum lolos → redirect ke layar yang sesuai.
- Setelah setup selesai, rute `chat` adalah home. **Memory & settings diakses dari
  AppBar chat** (bookmark → `/memory`, gear → `/settings`); profile sheet → edit persona.
- Rute yang **tidak boleh** diakses tanpa prasyarat: `chat`, `memory`, `settings`.

---

## 8. Checklist Desain untuk Setiap Fitur Baru

1. [ ] Baca `DESIGN.md` ini + `FEATURES.md` sebelum menulis UI.
2. [ ] Semua warna/spacing/radius/durasi dari tokens `core/design/`.
3. [ ] Komponen shared dipakai dari `core/design/components/` (jangan buat duplikat).
4. [ ] Layar diuji di dark & light mode.
5. [ ] Target sentuh ≥ 48 dp; teks mengikuti Dynamic Type; label Semantics ada.
6. [ ] Motion mengikuti token durasi & easing; hormati reduced motion.
7. [ ] Empty state & error state (bukan hanya golden path) sudah dirancang.
8. [ ] Tidak ada string hardcode — semua dari `core/l10n/` (atau konstanta fitur).

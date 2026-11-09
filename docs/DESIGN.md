# DESIGN — Sistem Desain VirtualHeart

Tema **Sakura Romance**: permukaan blush pink, aksen ungu elektrik (Electro), tipografi serif
Jepang untuk judul. Mode default **Light**; Dark dirancang independen (bukan inversi); mode
System mengikuti OS.

Semua widget memakai `package:material_ui/material_ui.dart`. Token ada di
`lib/core/design/tokens/`.

## 1. Warna (`AppColors`)

| Token | Light | Dark | Pemakaian |
| --- | --- | --- | --- |
| `background` / `backgroundDark` | `#FDF4F7` | `#120D14` | scaffold |
| `surface` / `surfaceDark` | `#FFFFFF` | `#1D1420` | kartu, sheet |
| `surfaceElevated` / `…Dark` | `#FBE7EF` | `#2A1B26` | field input, panel |
| `primary` / `primaryDark` | `#C24D7E` | `#F28CB0` | fill tombol, ikon besar |
| `primaryDeep` / `…Dark` | `#9E3A63` | `#F8A9C6` | teks kecil (kontras ≥ 4.5:1) |
| `primarySoft` / `…Dark` | `#F8DCE7` | `#47223A` | chip, badge |
| `secondary` / `secondaryDark` | `#6D4FA8` | `#B79BE0` | aksen Electro |
| `secondarySoft` / `…Dark` | `#EFE6FA` | `#352652` | latar chip sekunder |
| `accent` / `accentDark` | `#E8546E` | `#F4778C` | hati, aksi destruktif ringan |
| `gold` / `goldDark` | `#C9A227` | `#E8C766` | sparkle dekoratif |
| `textPrimary` / `…Dark` | `#241021` | `#F7EFF5` | teks utama |
| `textSecondary` / `…Dark` | `#6E5466` | `#C4AEC0` | teks sekunder |
| `error` / `errorDark` | `#C03948` | `#EE6B77` | error, reset |
| `success`, `warning`, `divider` | lihat file | varian `…Dark` | status & garis |

Aturan: widget mengambil warna dari `Theme.of(context).colorScheme` untuk surface/outline;
token langsung hanya untuk aksen brand. Tidak ada alias kompatibilitas lama — cukup token di
atas. Tidak ada token elevation: semua permukaan **flat** (tanpa shadow), kedalaman dibangun dari
kontras warna + radius.

## 2. Tipografi (`AppTextStyles`)

Font: **Shippori Mincho** (judul), **Nunito** (body/UI), dimuat `google_fonts`.

| Helper | Ukuran/berat | Dipakai untuk |
| --- | --- | --- |
| `appName()` | 22 / w700 | nama app di splash |
| `personaName()` | 18 / w600 | AppBar chat |
| `headingLarge()` | 20 / w700 | judul layar/section besar |
| `headingSmall()` | 16 / w600 | sub-judul, label kartu |
| `bubbleText()` | 15 / w400 | isi chat bubble (markdown) |
| `settingsLabel()` | 14 / w500 | label settings |
| `bodyMedium()` | 14 / w400 | body umum |
| `moodIndicator()` | 12 / w400 | subtitle mood |
| `timestamp()` | 11 / w300 | waktu pesan |
| `inputHint()` | 14 / w400 | hint input |
| `button()` | 14 / w600 | label tombol |

Semua helper menerima `Color? color`. **Default `null`** → warna mengikuti
`DefaultTextStyle`/theme, sehingga otomatis benar di dark mode.

## 3. Spacing, radius, ukuran (`AppSizes`)

- Spacing: `spaceXxs 4`, `spaceXs 8`, `spaceSm 12`, `spaceMd 16`, `spaceLg 24`,
  `spaceXl 32`, `spaceXxl 48`.
- Radius: `radiusSm 8`, `radiusMd 16`, `radiusLg 24`, `radiusFull 999`.
- Ikon: `iconSm 16`, `iconMd 24`, `iconLg 32`.
- Avatar: `avatarSm 36`, `avatarMd 52`, `avatarLg 96`.
- Chat: `bubbleMaxWidthFraction 0.75`, `bubblePaddingH 14`, `bubblePaddingV 10`,
  `inputBarHeight 56`.
- Aksesibilitas: `touchTarget 48` (target sentuh minimum).

Alias lama (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `radiusXl`) masih ada untuk kode yang belum
dimigrasi; jangan dipakai untuk kode baru.

## 4. Motion (`AppDurations`)

| Token | Nilai | Dipakai untuk |
| --- | --- | --- |
| `durationFast` | 120 ms | hover, toggle, chip |
| `durationNormal` | 240 ms | transisi halaman, sheet |
| `durationSlow` | 400 ms | hero, onboarding |
| `curveStandard` | `easeOutCubic` | mayoritas animasi |
| `curveEmotive` | `easeInOutBack` | heartbeat, bounce |

Animasi deklaratif memakai `flutter_animate`. Semua animasi loop/dekoratif memeriksa
`MediaQuery.disableAnimationsOf(context)` (reduced motion) dan berhenti bila aktif.

## 5. Komponen (`lib/core/design/components/`)

| Nama | Jenis | Catatan |
| --- | --- | --- |
| `PrimaryButton` | kelas | tombol utama (fill primary), mendukung `loading` + `icon` |
| `SecondaryButton` | kelas | outline |
| `GhostButton` | kelas | teks tanpa border |
| `AppIconButton` | kelas | ikon 48×48 dengan tooltip |
| `SpeakerButton` | kelas | tombol putar/berhenti TTS di bubble |
| `sectionCard(context:, children:)` | **fungsi** | kontainer surface + radius `radiusLg` + divider antar anak |
| `sectionHeader(context, title, icon)` | **fungsi** | judul uppercase + ikon |
| `showConfirmDialog(...)` | **fungsi** | dialog konfirmasi; `cancelLabel` wajib, `destructive` default `true` |
| `EmptyState` | kelas | ikon + judul + body + aksi |
| `SakuraBackground` | kelas | kelopak sakura `CustomPainter` (tanpa aset) |
| `SakuraDivider` | kelas | pemisah dekoratif |

## 6. Chat

- **AppBar**: avatar persona (ketuk → profile sheet) + nama + subtitle mood (`MoodIndicator`),
  aksi memory & settings. Tidak ada chip mood di bubble; mood hanya di header/profil.
- **Bubble**: user = fill `primary` (teks `onPrimary`); AI = `surfaceContainer` (teks
  `onSurface`). Isi AI dirender markdown (`GptMarkdown`). Timestamp **muncul saat bubble
  diketuk** (toggle), bukan selalu tampil. Bubble AI punya `SpeakerButton`.
- **Input bar**: field pill radius `radiusMd`, batas 2000 karakter, tombol mic + kirim 48×48.
  Tidak ada tombol stop: input dinonaktifkan selama AI menjawab (`known issue`). Saat merekam,
  hanya ikon mic yang berubah status — tidak ada waveform.
- **Streaming**: bubble sementara (`ValueKey('streaming')`) + `TypingIndicator` sebelum token
  pertama.

## 7. Persona

- `PersonaSetupScreen` dipakai untuk pembuatan awal **dan** edit (dibuka dari
  `PersonaEditSheet`).
- `PersonaProfileSheet` (dari AppBar chat): avatar besar (72), nama, gender, panggilan sayang,
  kartu mood (emoji + intensitas), chip hobi, kartu kepribadian, tombol Edit yang menutup sheet
  dengan hasil `true`; pemanggil lalu membuka `PersonaEditSheet`. Sheet bukan route.
- 6 avatar per gender (`avatar_catalog.dart`), dirender sebagai gradien radial + ikon.

## 8. Notifikasi

- Kanal Android: `vh_morning` (Morning Message), `vh_checkin` (Check-in),
  `vh_special` (Special Day); ikon memakai launcher (`@mipmap/ic_launcher`).
- Semua notifikasi memakai payload `chat`; ketuk notifikasi → `/chat` bila seluruh gate selesai
  dan model siap (cold start ditangani lewat `takePendingTap`).
- Jadwal memakai zona waktu lokal perangkat; mode `exactAllowWhileIdle` bila izin exact alarm
  diberikan, selain itu `inexactAllowWhileIdle`.

## 9. Aksesibilitas

- Target sentuh minimum 48 dp; kontras teks kecil memakai `primaryDeep`/`textSecondary`.
- `Semantics` baru sebagian dipakai (mis. dekorasi sparkle diberi label `null`); label eksplisit
  untuk tombol ikon belum menyeluruh — lihat `KNOWN_ISSUES.md`.
- Reduced motion dihormati pada animasi dekoratif.
- Material localization aktif untuk `id` dan `en` (`GlobalMaterialLocalizations.delegates`).

## 10. Struktur & navigasi

- Struktur `lib/`, daftar provider, dan aturan layer: lihat [`ARCHITECTURE.md`](ARCHITECTURE.md).
- Navigasi: `resolveRedirect` di `core/router/app_router.dart`; `/model-download` tetap
  membutuhkan age gate + onboarding + persona. Matriks lengkap ada di `ARCHITECTURE.md` §4.

## 11. Checklist perubahan UI

- [ ] Warna/ukuran/durasi dari token, bukan angka mentah.
- [ ] Teks lewat `AppStrings` (ID + EN); tambahkan ke ketiga kelas.
- [ ] `Color?` tidak dipaksa ke warna light bila seharusnya mengikuti theme.
- [ ] Uji light & dark, teks panjang, serta `disableAnimations`.
- [ ] Tidak ada widget yang memanggil engine AI/plugin langsung.
- [ ] Screenshot/verifikasi di layar nyata (atau catat sebagai unverified).

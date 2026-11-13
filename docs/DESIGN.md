# DESIGN — Sistem Desain VirtualHeart

Sistem desain **Multi-Theme Atelier**: permukaan editorial datar dengan bingkai hairline 1px,
tipografi adaptif tema, dan **4 preset tema** yang masing-masing mendukung mode **Light** &
**Dark** independen:

1. **Editorial** (default): *Atelier Ivory* (Light) / *Obsidian Ink* (Dark) — display **Newsreader**.
2. **Romantic**: *Silk & Garnet* (Light) / *Velvet Nocturne* (Dark) — display **Cormorant Garamond**.
3. **Classic**: *Parchment & Navy* (Light) / *Midnight Study* (Dark) — display **Lora**.
4. **Botanical**: *Limestone & Moss* (Light) / *Deep Pine* (Dark) — display **Outfit**.

Mode kecerahan default **Light**; **Dark** dirancang independen (bukan inversi); **System** mengikuti OS.
Body/UI seluruh tema memakai **Inter** (`tabularFigures` untuk timestamp, caption, badge).

Semua widget memakai `package:material_ui/material_ui.dart`. Token ada di
`lib/core/design/tokens/`; bingkai di `app_effects.dart`.

## 1. Warna (`AppPalette`, `AppPalettes`, `AppColors`)

`AppPalette` (`ThemeExtension<AppPalette>`) memegang 23 token warna per kombinasi
`AppThemeStyle` × `Brightness` (8 palet independen di `AppPalettes.resolve(style, brightness)`):

| Token | Pemakaian |
| --- | --- |
| `background` | kanvas scaffold |
| `surface` | kartu, sheet, input bar |
| `surfaceElevated` / `surfaceMuted` | panel naik & bidang tenang |
| `primary` / `textOnPrimary` | aksi utama & teks di atas tombol utama |
| `primaryDeep` / `primarySoft` | teks kecil kontras ≥ 4.5:1 / kontainer halus |
| `secondary` / `secondarySoft` | aksen kedua (rail thread, cincin orbital) |
| `accent` / `accentDeep` | dekoratif / teks aksen kecil |
| `gold` / `goldText` | aksen hangat / teks kategori tanggal |
| `textPrimary` / `textSecondary` | teks utama & sekunder |
| `divider` | hairline 1px (`outlineVariant`) |
| `error` / `success` / `warning` | status semantik |
| `userBubbleBg` / `bubbleUserOn` / `userBubbleBorder` | kapsul pesan pengguna solid |

Palet default statis (`AppColors`): *Editorial Light ("Atelier Ivory")* (`background #FAF8F4`,
`surface #FFFFFF`, `primary #18181D`, `secondary #7A5616`, `accentDeep #9C3A25`,
`textPrimary #141418`, `textSecondary #5A5652`, `divider #E4DED4`, `userBubbleBg #1A191F`).

Aturan:

- Widget mengambil surface/outline dari `Theme.of(context).colorScheme`; warna khusus tema
  mengambil via `AppColors.paletteOf(context)` atau helper `primaryDeepFor`, `accentFor`,
  `accentDeepFor`, `secondaryFor`, `goldFor`, `goldTextFor`, `userBubbleBgFor`,
  `bubbleUserOnFor`, `userBubbleBorderFor`, `successFor`, `errorFor`, `textSecondaryFor`,
  `backgroundFor`, `surfaceFor`, `surfaceElevatedFor`, `dividerFor`.
- Seluruh pasangan teks/permukaan di semua 8 palet wajib memenuhi kontras **≥ 4.5:1** (dijaga
  oleh `test/core/design_contrast_test.dart`).

## 2. Garis & Bingkai (`AppBorders`)

Tanpa gradien berat dan tanpa drop shadow.

| Helper | Isi |
| --- | --- |
| `AppBorders.hairline(context, {alpha})` | `BorderSide` 1px memakai `outlineVariant` |
| `AppBorders.accent(context, {width})` | `BorderSide` 1.5px memakai `colorScheme.primary` |
| `AppBorders.cardDecoration(context, {radius, selected, color})` | `BoxDecoration` datar + border 1px (1.5px saat terpilih) |

## 3. Tipografi (`AppTextStyles`)

Display/heading otomatis mengikuti `AppColors.paletteOf(context).style` (atau `*ForStyle(style)`
di `AppTheme.lightFor` / `AppTheme.darkFor`). Body/UI memakai **Inter** via `google_fonts`.

| Helper | Ukuran/berat/tinggi | Dipakai untuk |
| --- | --- | --- |
| `displayHero(context)` | 38 / w600 / 1.08 | nama app di splash |
| `displayLarge(context)` | 32 / w600 / 1.12 | `TextTheme.displayMedium` |
| `displayMedium(context)` | 27 / w600 / 1.16 | judul kartu utama |
| `displaySmall(context)` | 24 / w600 / 1.18 | judul halaman/blok (Hub, Memory, Settings, Profil, Empty chat) |
| `appName(context)` | 30 / w600 / 1.15 | brand |
| `personaName(context)` | 20 / w600 / 1.2 | AppBar chat |
| `headingLarge(context)` | 22 / w600 / 1.2 | judul layar/section |
| `headingMedium(context)` | 19 / w600 / 1.25 | dialog, inisial avatar |
| `headingSmall(context)` | 17 / w600 / 1.3 | sub-judul, label sheet, kartu |
| `bodyLarge()` / `bodyMedium()` / `bodySmall()` | 15 / 14 / 12.5 w400 | teks isi |
| `bubbleText()` | 15 / w400 / 1.55 | isi pesan chat |
| `settingsLabel()` | 15 / w600 / 1.35 | label settings & kartu opsi |
| `titleLarge()` / `titleSmall()` | 18 / 13 w600 | judul UI / metadata thread |
| `inputHint()` | 15 / w400 / 1.4 | hint input |
| `button()` | 15 / w600 / 1.2 | label tombol |
| `moodIndicator()` | 12.5 / w500 / 1.3 | mood pill |
| `timestamp()` | 11 / w500 / 1.2 | waktu pesan, counter (`tabularFigures`) |
| `sectionLabel()` | 11 / w700 / 1.2 (ls 1.2) | label section uppercase |
| `caption()` / `badge()` | 12 / 10.5 (`tabularFigures`) | catatan & badge jumlah |

## 4. Spacing, radius, ukuran (`AppSizes`)

- Spacing: `spaceXxs 4`, `spaceXs 8`, `spaceSm 12`, `spaceMd 16`, `spaceLg 24`,
  `spaceXl 32`, `spaceXxl 48`.
- Layout: `contentMaxWidth 720`, `bubbleMaxWidth 560`, `pageGutter 20`,
  `controlHeight 50`, `rowMinHeight 58`, `inputMaxHeight 132`, `chatInputHeight 56`,
  `bubbleTail 4`.
- Radius: `radiusXs 4`, `radiusSm 8`, `radiusBadge 6`, `radiusSegment 10`, `radiusMd 12`,
  `radiusControl 12`, `radiusPanel 14`, `radiusLg 16`, `radiusCard 16`, `radiusSheet 20`,
  `radiusBubble 16`, `radiusFull 999`.
- Ikon: `iconSm 16`, `iconMd 24`, `iconLg 32`, `iconBadge 36`, `iconBadgeSm 28`.
- Avatar: `avatarXs 28`, `avatarSm 36`, `avatarNav 44`, `avatarMd 52`, `avatarCard 64`,
  `avatarRail 76`, `avatarProfile 92`, `avatarLg 96`, `avatarHero 112`.
- Aksesibilitas: `touchTarget 48`.

## 5. Motion (`AppDurations`)

| Token | Nilai | Dipakai untuk |
| --- | --- | --- |
| `durationInstant` | 90 ms | perubahan warna/opacity |
| `durationFast` | 140 ms | hover, toggle, chip, pesan masuk |
| `durationNormal` | 260 ms | transisi halaman, sheet |
| `durationSlow` | 420 ms | hero, onboarding |
| `durationOrbital` | 3200 ms | siklus rotasi halus `ResonanceMark` |
| `stagger` | 60 ms | jeda antar item |
| `curveStandard` | `easeOutCubic` | mayoritas animasi |
| `curveEmotive` | `easeInOutCubic` | transisi dua arah |
| `curveSpring` | `easeOutBack` | pop state |

Setiap animasi dekoratif/loop memeriksa `MediaQuery.disableAnimationsOf(context)` dan berhenti
statis (`ResonanceMark`, `_BootHairline`, `_PulseSquare`, pulse mic).

## 6. Shell & komponen (`lib/core/design/components/`)

| Nama | Jenis | Catatan |
| --- | --- | --- |
| `AppScaffold` | kelas | `Stack[AppBackground, Scaffold transparan]`; mendukung `bottomNavigationBar` |
| `AppContent` | kelas | `Center > ConstrainedBox(maxWidth) > Padding(pageGutter)` |
| `AppBackground` | kelas | kanvas `palette.background` + radial sheen sudut statis 6% |
| `MainShellScaffold` | kelas | dock bawah hairline 4-tab (Hub, Chat, Memory, Settings), sinkron ke `activeShellTabProvider` |
| `ResonanceMark` | kelas | emblem orbital dual-ring 1.25px + titik/ikon pusat; rotasi opsional |
| `AppIconBadge` | kelas | ikon dalam bingkai `radiusSm` 8 + hairline border |
| `appSheetHandle` / `appSheetHeader` | fungsi | handle 32×3 + judul sheet + tombol tutup |
| `showAppSheet` | fungsi | modal sheet transparan, `useSafeArea`, barrier 45% |
| `PrimaryButton` | kelas | solid `scheme.primary`, `radiusControl` 12, tinggi 50, `loading`/`icon` |
| `SecondaryButton` / `GhostButton` | kelas | outline 1px (`radiusControl` 12) / tombol teks minimal 48dp |
| `AppIconButton` | kelas | ikon 48×48, `radiusSm` 8, `bordered` opsional |
| `SpeakerButton` | kelas | visual `32×32` `radiusSm` hairline dalam hit 48, ikon putar/stop |
| `sectionHeader(context, title, icon, {trailing})` | fungsi | ikon 16px + label uppercase `sectionLabel` |
| `sectionCard(context:, children:)` | fungsi | kartu datar `radiusCard` 16, border 1px `outlineVariant`, divider penuh antar anak |
| `showConfirmDialog(...)` | fungsi | dialog konfirmasi datar; `cancelLabel` wajib |
| `EmptyState` | kelas | bingkai ikon `radiusCard` atau `mark: true` (`ResonanceMark`) |
| `DoubleBackExitScope` | kelas | penjaga back 2x untuk keluar (SnackBar 2 dtk) + intersep tab/halaman akar |

## 7. Pola layar & Navigasi 4-Tab

- **Splash**: `ResonanceMark(112)`, nama app `displayHero`, tagline tracked uppercase, `_BootHairline`.
- **Age gate**: header lockup + badge `13+`, kartu hairline berisi `AppIconBadge`, tautan privasi
  interaktif, tombol konfirmasi/tolak.
- **Onboarding**: header lockup + step counter (`01 / 03`) + Skip, `ResonanceMark` berikon di
  panggung hairline `220×220`, bar indikator datar.
- **Main Shell (4 Tab)**:
  1. **Hub** (`/hub` — `CompanionHubScreen`): portrait & mood meter persona, CTA *Open Chat* /
     *View Profile*, 3 *Conversation Starters* yang mengisi `pendingChatDraftProvider` lalu pindah
     ke `/chat`, serta snapshot Memori & Mesin Lokal responsif (1/2 kolom).
  2. **Chat** (`/chat` — `ChatScreen`): AppBar 64dp (avatar + nama + `MoodIndicator` + tombol
     profil), daftar pesan, `InputBar` hairline datar.
  3. **Memory** (`/memory` — `MemoryScreen`): tab-native header + badge jumlah + hapus semua,
     pencarian hairline, section per kategori.
  4. **Settings** (`/settings` — `SettingsScreen`): tab-native header + 7 section; `AppearanceSection`
     menyediakan mode kecerahan (Light/Dark/System) + grid 4 preset tema dengan swatch ganda.
- **Persona setup/edit & Model & Privacy**: seluruhnya memakai kartu hairline datar tanpa shadow.

## 8. Chat

- **User**: kapsul solid kanan (`userBubbleBg` + border `userBubbleBorder`), sudut ekor 4dp, teks
  `bubbleUserOn`, tap untuk toggle timestamp tabular.
- **Assistant (Editorial Thread)**: blok kiri ber-rail vertikal 2px (`scheme.secondary`), baris
  header (`personaAvatar(24)` + nama persona + `SpeakerButton` opsional), isi `GptMarkdown`
  langsung di kanvas (gambar markdown disanitasi demi privasi).
- **Input bar**: kontainer datar `radiusCard` 16 berborder 1px, tombol mic & kirim/stop `40×40`
  `radiusSm` 8 dalam target sentuh 48×48. Batas 2000 karakter (counter muncul ≥ 1800).

## 9. Persona

- `PersonaSetupScreen` untuk pembuatan awal; edit memakai `PersonaEditSheet`.
- `PersonaProfileSheet`: kartu hero + kartu telemetri mood (progress bar 4px) + kepribadian +
  tag hobi + tombol Edit sticky.
- 6 avatar per gender (`avatar_catalog.dart`) dengan palet duotone editorial kontras tinggi;
  `personaAvatar` memakai inisial adaptif font preset aktif.

## 10. Notifikasi

- Kanal Android: `vh_morning`, `vh_checkin`, `vh_special`; ikon memakai launcher (`@mipmap/ic_launcher`).
- Tap notifikasi → `/chat` (tab 1 di shell) bila seluruh gate selesai dan model siap.
- Jadwal memakai zona waktu lokal perangkat.

## 11. Aksesibilitas

- Target sentuh minimum 48 dp; baris settings `rowMinHeight 58`.
- Invarian kontras ≥ 4.5:1 di seluruh 8 palet dijaga oleh `test/core/design_contrast_test.dart`.
- Animasi dekoratif dan rotasi dimatikan saat `MediaQuery.disableAnimationsOf(context)`.
- Material localization aktif untuk `id` dan `en`.

## 12. Struktur & navigasi

- Struktur `lib/`, daftar provider, dan aturan layer: lihat [`ARCHITECTURE.md`](ARCHITECTURE.md).
- Navigasi: `resolveRedirect` di `core/router/app_router.dart`; pasca-setup mengarah ke `/hub`.
- Tombol back di halaman akar (`MainShellScaffold`/tab Hub, layar setup awal) memakai `DoubleBackExitScope`: tekan back di tab non-Hub kembali ke Hub, sedangkan tekan pertama di layar akar menampilkan `AppStrings.exitBackAgainPrompt` dan tekan kedua dalam 2 detik baru menutup aplikasi.

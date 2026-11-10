# DESIGN — Sistem Desain VirtualHeart

Tema **Sakura Dusk / Senja Sakura**: kertas ivory hangat, tinta plum, satu aksen rose yang
tenang, lavender sebagai aksen kedua. Serif lembut (Fraunces) untuk display, sans humanis
(Plus Jakarta Sans) untuk UI. Nuansa romantis datang dari warna, cahaya, bentuk organik, dan
motion halus — bukan dekorasi berlebih.

Mode default **Light**; Dark dirancang independen (bukan inversi); mode System mengikuti OS.

Semua widget memakai `package:material_ui/material_ui.dart`. Token ada di
`lib/core/design/tokens/`; efek (gradien/bayangan) di `app_effects.dart`.

## 1. Warna (`AppColors`)

| Token | Light | Dark | Pemakaian |
| --- | --- | --- | --- |
| `background` / `…Dark` | `#FFF8F4` | `#140F16` | scaffold |
| `surface` / `…Dark` | `#FFFDFB` | `#1E1620` | kartu, sheet, bubble AI |
| `surfaceElevated` / `…Dark` | `#FFF1EE` | `#2A1F2B` | panel naik |
| `surfaceMuted` / `…Dark` | `#F8E7ED` | `#332434` | bidang tenang |
| `primary` / `primaryDark` | `#B23A63` | `#F7A0BD` | fill tombol, ikon besar |
| `primaryDeep` / `…Dark` | `#8C2A4E` | `#FFC2D6` | teks kecil (≥ 4.5:1) |
| `primarySoft` / `…Dark` | `#FBE0E9` | `#4A2338` | chip, badge |
| `secondary` / `secondaryDark` | `#7357B8` | `#C9AEF5` | aksen lavender |
| `secondarySoft` / `…Dark` | `#EFE9FA` | `#362A4E` | latar chip sekunder |
| `accent` / `accentDark` | `#D95669` | `#FF8A9C` | dekoratif (jangan teks kecil) |
| `accentDeep` / `…Dark` | `#A63C4E` | `#FFB0BE` | teks kecil di atas surface |
| `gold` / `goldDark` | `#C79A3B` | `#EACB7A` | sparkle dekoratif |
| `goldText` / `…Dark` | `#8F6A1F` | `#F0D79A` | teks kecil kategori tanggal |
| `textPrimary` / `…Dark` | `#2A1620` | `#FBF1F6` | teks utama |
| `textSecondary` / `…Dark` | `#6F5464` | `#CDB6C7` | teks sekunder |
| `textOnPrimary` / `…Dark` | `#FFF9FB` | `#2A0E1E` | teks di atas primary |
| `divider` / `…Dark` | `#F0DDE5` | `#3B2A3C` | hairline |
| `error` / `errorDark` | `#B93B4A` | `#FF8D98` | error, reset |
| `success` / `warning` | `#3C7A55` / `#966A20` | varian `…Dark` | status |

Gradien & permukaan khusus: `actionStart/actionEnd`, `bubbleUserStart/bubbleUserEnd`,
`bubbleUserOn`, `bgTop/bgMid/bgBottom`, `profileTop/profileMid/profileEnd` (masing-masing punya
varian `…Dark`).

Aturan:

- Widget mengambil surface/outline dari `Theme.of(context).colorScheme`; token langsung hanya
  untuk aksen brand.
- Warna eksplisit wajib lewat helper brightness-aware: `primaryDeepFor`, `accentFor`,
  `accentDeepFor`, `secondaryFor`, `goldFor`, `goldTextFor`, `bubbleUserOnFor`, `successFor`,
  `errorFor`, `textSecondaryFor`.
- `accent` dan `gold` murni dekoratif — teks kecil memakai `accentDeep`/`goldText`.
- Tidak ada alias ukuran lama; semua memakai nama token di §3.

## 2. Efek (`AppGradients`, `AppShadows`)

| Helper | Isi |
| --- | --- |
| `AppGradients.primaryAction(context)` | `actionStart → actionEnd`, tombol utama & mic/send aktif |
| `AppGradients.userBubble(context)` | `bubbleUserStart → bubbleUserEnd`, bubble user |
| `AppGradients.background(context)` | `bgTop → bgMid → bgBottom`, latar aplikasi |
| `AppGradients.profileHeader(context)` | `profileTop → profileMid → profileEnd`, hero profil |
| `AppGradients.selectedRing(context)` | `primary → secondary`, indikator halaman |
| `AppGradients.bloom(context)` | radial `primaryContainer → primary` |
| `AppShadows.card(context)` | dua lapis bayangan plum lembut (dark: hitam) |
| `AppShadows.floating(context)` | bayangan lebih tinggi untuk input bar |
| `AppShadows.glow(context, color)` | glow berwarna (tombol utama, BloomMark) |

Semua fungsi memilih token `…Dark` saat `Theme.of(context).brightness == Brightness.dark`.

## 3. Tipografi (`AppTextStyles`)

Font: **Fraunces** (display/heading), **Plus Jakarta Sans** (body/UI) lewat `google_fonts`.
`AppTheme` membangun `TextTheme` dari helper ini — jangan mendefinisikan ukuran kedua kali.

| Helper | Ukuran/berat/tinggi | Dipakai untuk |
| --- | --- | --- |
| `displayHero()` | 38 / w600 / 1.08 | nama app di splash |
| `displayLarge()` | 32 / w600 / 1.12 | `TextTheme.displayMedium` |
| `displayMedium()` | 27 / w600 / 1.16 | judul kartu utama |
| `displaySmall()` | 24 / w600 / 1.18 | judul blok (profil, empty chat) |
| `appName()` | 30 / w600 / 1.15 | brand |
| `personaName()` | 20 / w600 / 1.2 | AppBar chat |
| `headingLarge()` | 22 / w600 / 1.2 | judul layar/section |
| `headingMedium()` | 19 / w600 / 1.25 | dialog, kartu |
| `headingSmall()` | 17 / w600 / 1.3 | sub-judul, label sheet |
| `bodyLarge()` | 15 / w400 / 1.55 | body utama |
| `bodyMedium()` | 14 / w400 / 1.5 | body umum |
| `bodySmall()` | 12.5 / w400 / 1.45 | bantuan, subjudul baris |
| `bubbleText()` | 15 / w400 / 1.55 | isi chat bubble |
| `settingsLabel()` | 15 / w600 / 1.35 | label settings |
| `titleLarge()` | 18 / w600 / 1.3 | judul UI |
| `titleSmall()` | 13 / w600 / 1.35 | label kecil |
| `inputHint()` | 15 / w400 / 1.4 | hint input |
| `button()` | 15 / w600 / 1.2 | label tombol |
| `moodIndicator()` | 12.5 / w500 / 1.3 | mood pill |
| `timestamp()` | 11 / w500 / 1.2 | waktu pesan, counter |
| `sectionLabel()` | 11 / w700 / 1.4 | label section uppercase |
| `caption()` | 12 / w500 / 1.4 | catatan |
| `badge()` | 10.5 / w700 / 1.2 | badge |

Semua helper menerima `Color? color`; `null` mengikuti theme.

## 4. Spacing, radius, ukuran (`AppSizes`)

- Spacing: `spaceXxs 4`, `spaceXs 8`, `spaceSm 12`, `spaceMd 16`, `spaceLg 24`,
  `spaceXl 32`, `spaceXxl 48`.
- Layout: `contentMaxWidth 720`, `bubbleMaxWidth 560`, `pageGutter 24`,
  `controlHeight 52`, `rowMinHeight 60`, `inputMaxHeight 132`, `chatInputHeight 56`,
  `bubbleTail 6`.
- Radius: `radiusXs 6`, `radiusSm 10`, `radiusBadge 12`, `radiusSegment 14`, `radiusMd 16`,
  `radiusControl 18`, `radiusPanel 20`, `radiusLg 24`, `radiusCard 28`, `radiusSheet 32`,
  `radiusBubble 22`, `radiusFull 999`.
- Ikon: `iconSm 16`, `iconMd 24`, `iconLg 32`, `iconBadge 36`, `iconBadgeSm 28`.
- Avatar: `avatarXs 28`, `avatarSm 36`, `avatarNav 44`, `avatarMd 52`, `avatarCard 64`,
  `avatarRail 76`, `avatarProfile 92`, `avatarLg 96`, `avatarHero 112`.
- Aksesibilitas: `touchTarget 48` (target sentuh minimum).

## 5. Motion (`AppDurations`)

| Token | Nilai | Dipakai untuk |
| --- | --- | --- |
| `durationInstant` | 90 ms | perubahan warna/opacity |
| `durationFast` | 140 ms | hover, toggle, chip, bubble masuk |
| `durationNormal` | 260 ms | transisi halaman, sheet |
| `durationSlow` | 420 ms | hero, onboarding |
| `durationBreath` | 2600 ms | siklus napas BloomMark |
| `stagger` | 60 ms | jeda antar item |
| `curveStandard` | `easeOutCubic` | mayoritas animasi |
| `curveEmotive` | `easeInOutCubic` | napas & transisi dua arah |
| `curveSpring` | `easeOutBack` | pop state |

Aturan: setiap animasi dekoratif/loop memeriksa `MediaQuery.disableAnimationsOf(context)` dan
berhenti statis (BloomMark, titik boot, typing dots, sparkle, pulse mic). Transisi route
memakai fade + naik 8 px dan dilewati sepenuhnya saat reduced motion.

## 6. Shell & komponen (`lib/core/design/components/`)

| Nama | Jenis | Catatan |
| --- | --- | --- |
| `AppScaffold` | kelas | `Stack[AppBackground, Scaffold transparan]`; `safeArea` untuk layar dengan app bar/own SafeArea |
| `AppContent` | kelas | `Center > ConstrainedBox(maxWidth) > Padding(pageGutter)` |
| `AppBackground` | kelas | gradien senja + dua glow radial + blossom bezier statis; `petals`, `intensity` |
| `BloomMark` | kelas | lima kelopak + ikon; `animate`, `glow`; menghormati reduced motion |
| `AppIconBadge` | kelas | ikon dalam wadah radius 12 dengan alpha tema |
| `appSheetHandle` / `appSheetHeader` | fungsi | handle 36×4 + judul sheet + tombol tutup |
| `showAppSheet` | fungsi | modal sheet transparan, `useSafeArea`, barrier 45% |
| `PrimaryButton` | kelas | gradien aksi + glow, pill, tinggi 52, `loading`/`icon` |
| `SecondaryButton` | kelas | tonal outline lavender |
| `GhostButton` | kelas | teks tanpa fill |
| `AppIconButton` | kelas | ikon 48×48, latar `surfaceContainerLow`, tooltip tunggal |
| `SpeakerButton` | kelas | ripple, visual 32 di hit 48, ikon putar/stop |
| `sectionHeader(context, title, icon, {trailing})` | fungsi | badge ikon + label uppercase `sectionLabel` |
| `sectionCard(context:, children:)` | fungsi | kartu `radiusCard`, hairline `outlineVariant`, `AppShadows.card`, divider antar anak |
| `showConfirmDialog(...)` | fungsi | dialog konfirmasi; `cancelLabel` wajib, `destructive` default `true` |
| `EmptyState` | kelas | lingkaran ikon atau `bloom: true`, judul + body opsional + aksi |

Settings menambah `SettingsSection`, `SettingsRow`, dan `SettingsPermissionRow` di
`lib/features/settings/widgets/`; semua baris settings memakai `SettingsRow`.

## 7. Pola layar

- **Splash**: `BloomMark` bernapas, nama app `displayHero`, tagline `caption`, tiga titik boot.
- **Age gate**: satu kartu ivory dengan lingkaran shield, judul `displaySmall`, tautan privasi di
  atas tombol (selalu terlihat di viewport kecil), lalu konfirmasi + tolak.
- **Onboarding**: brand lockup + skip, `BloomMark` per halaman dalam halo radial, bar indikator
  bergradien, satu tombol utama.
- **Persona setup/edit**: header `BloomMark`, kartu gender, rail avatar dengan ring, field
  bertema, kartu kepribadian (dua kolom ≥ 520 dp), chip hobi, footer aksi sticky.
- **Model**: hero marka + subjudul, tile model terpilih dengan badge & pill ukuran, field token,
  kartu progres, kartu error.
- **Memory**: judul tunggal + pill jumlah, pencarian pill dengan aksi bersih, kartu per kategori,
  baris fakta dengan hapus eksplisit (konfirmasi) dan tooltip sumber.
- **Settings**: section berurutan; tema = tiga kartu pilihan; baris seragam; status izin jujur.
- **Privacy**: satu kartu `radiusCard` berisi `SelectableText`.

## 8. Chat

- **AppBar** 68 dp transparan + hairline bawah: avatar persona (ketuk → profile sheet), nama
  `personaName`, pill mood (`MoodIndicator`), aksi memory & settings `AppIconButton`.
- **Bubble**: user = gradien `userBubble` (teks `bubbleUserOn`), AI = `surface` + hairline
  `outlineVariant` (teks `onSurface`), keduanya radius 22 dengan ekor 6 di sudut avatar/pengirim,
  `AppShadows` sesuai peran. Isi AI dirender markdown (`GptMarkdown`, gambar disanitasi).
  Timestamp muncul saat bubble diketuk (toggle), bukan selalu tampil.
- **Input bar**: permukaan `surface` melayang (`radiusCard`, `AppShadows.floating`), field
  radius 22, batas 2000 karakter (counter muncul ≥ 1800), mic dan tombol kirim/stop 44 visual
  dalam hit 48. **Tombol stop ada** (FR-05) dan memakai ikon `stop_rounded` saat AI menjawab.
- **Streaming**: bubble sementara (`ValueKey('streaming')`) + `TypingIndicator` (avatar persona,
  bubble AI, tiga titik) sebelum token pertama.

## 9. Persona

- `PersonaSetupScreen` dipakai untuk pembuatan awal; edit memakai `PersonaEditSheet`.
- `PersonaProfileSheet` (dari AppBar chat): hero gradien + avatar 92, nama `displaySmall`,
  kartu mood (emoji, label, intensitas beranimasi), pill hobi, kartu kepribadian, tombol Edit
  yang menutup sheet dengan hasil `true`; pemanggil membuka `PersonaEditSheet` via `showAppSheet`.
- 6 avatar per gender (`avatar_catalog.dart`) dengan ikon per avatar; `avatarCircle` memakai
  gradien radial, highlight, glow, dan ring `primary` saat terpilih. `personaAvatar` memakai
  inisial Fraunces.

## 10. Notifikasi

- Kanal Android: `vh_morning` (Morning Message), `vh_checkin` (Check-in),
  `vh_special` (Special Day); ikon memakai launcher (`@mipmap/ic_launcher`).
- Semua notifikasi memakai payload `chat`; ketuk notifikasi → `/chat` bila seluruh gate selesai
  dan model siap (cold start ditangani lewat `takePendingTap`).
- Jadwal memakai zona waktu lokal perangkat; mode `exactAllowWhileIdle` bila izin exact alarm
  diberikan, selain itu `inexactAllowWhileIdle`.

## 11. Aksesibilitas

- Target sentuh minimum 48 dp; baris settings `rowMinHeight 60`.
- Kontras teks kecil memakai `primaryDeep`/`accentDeep`/`goldText`/`textSecondary` (light) dan
  varian `…Dark`; invarian ≥ 4.5:1 dijaga `test/core/design_contrast_test.dart`.
- Ikon aksi tanpa teks wajib punya `tooltip`/`Semantics`; sheet & kartu pilihan memakai
  `Semantics(button:, selected:)`.
- Animasi dekoratif dimatikan saat `MediaQuery.disableAnimationsOf(context)`, termasuk transisi
  route.
- Material localization aktif untuk `id` dan `en` (`GlobalMaterialLocalizations.delegates`).

## 12. Struktur & navigasi

- Struktur `lib/`, daftar provider, dan aturan layer: lihat [`ARCHITECTURE.md`](ARCHITECTURE.md).
- Navigasi: `resolveRedirect` di `core/router/app_router.dart`; `/model-download` tetap
  membutuhkan age gate + onboarding + persona. Matriks lengkap ada di `ARCHITECTURE.md` §4.

## 13. Checklist perubahan UI

- [ ] Warna/ukuran/durasi dari token, bukan angka mentah.
- [ ] Teks lewat `AppStrings` (ID + EN); tambahkan ke ketiga kelas.
- [ ] Warna eksplisit memakai helper brightness-aware.
- [ ] Layar baru memakai `AppScaffold`/`AppContent`, bukan `Scaffold` polos.
- [ ] Uji light & dark, lebar 320 dp, teks panjang, serta `disableAnimations`.
- [ ] Tidak ada widget yang memanggil engine AI/plugin langsung.
- [ ] Screenshot/verifikasi di layar nyata (atau catat sebagai unverified).

# FEATURES.md — VirtualHeart

Dokumen ini adalah **spesifikasi fitur** (Product Requirements) VirtualHeart hasil
refactor. Setiap fitur punya ID unik (FR-XX), prioritas, acceptance criteria, dan edge
case. Dokumen ditulis baru sebagai fondasi — bukan dokumentasi dari kode lama.

Dokumen ini **wajib** dibaca bersama:
- `docs/AGENTS.md` — aturan kerja
- `docs/DESIGN.md` — design system, UX, arsitektur
- `docs/WORKFLOW.md` — alur kerja pengembangan

---

## 1. Ringkasan Produk & Prinsip

**VirtualHeart** adalah aplikasi *romantic companion* AI yang berjalan **100% on-device**
(Small Language Model). Pengguna membuat dan berinteraksi dengan pasangan virtual yang
dipersonalisasi — tanpa akun, tanpa cloud, tanpa telemetri.

Prinsip produk (non-negosiasi):

| # | Prinsip | Implikasi |
|---|---|---|
| P1 | **Privasi total** | Semua inferensi, memori, dan data tersimpan lokal. Tidak ada panggilan jaringan. |
| P2 | **Personalisasi mendalam** | Persona, mood, dan memori membentuk pengalaman yang terasa hidup. |
| P3 | **Emosional, bukan utilitarian** | Bahasa UI & AI hangat dan manusiawi; fitur mendukung rasa ditemani. |
| P4 | **Tanpa akun** | Tidak ada login, sinkronisasi, atau akun cloud. |
| P5 | **Keselamatan konten** | Input & output melewati safety gate; fitur menolak konten berbahaya dengan anggun. |

**Prioritas fitur:**
- **P0** — wajib untuk rilis pertama (fondasi).
- **P1** — penting, menyusul segera.
- **P2** — peningkatan/eksperimen.

---

## 2. Format Spesifikasi

Setiap fitur mengikuti format:

```text
ID   : FR-XX
Nama : <nama fitur>
Prioritas : P0/P1/P2
Deskripsi : <apa dan mengapa>
Acceptance Criteria:
  - [ ] <kondisi terukur>
Edge Cases:
  - <skenario tepi & perilaku yang diharapkan>
```

> Fitur baru yang belum ada di dokumen ini **wajib** ditambahkan di sini sebelum
> dikerjakan (lihat checklist `AGENTS.md` §6).

---

## 3. Daftar Fitur

### Alur Awal (Setup Flow)

#### FR-01 — Age Gate (13+)
**Prioritas:** P0

**Deskripsi:** Layar verifikasi usia sebelum akses aplikasi. Aplikasi berisi konten
romantis/emosional sehingga perlu batas usia 13+.

**Acceptance Criteria:**
- [ ] Layar menampilkan pertanyaan usia dengan dua pilihan: "13 tahun ke atas" / "Di bawah 13 tahun".
- [ ] Konfirmasi "di bawah 13 tahun" menampilkan pesan hangat dan menutup aplikasi.
- [ ] Konfirmasi lolos menyimpan status (`isAgeVerified`) dan melanjutkan ke onboarding.
- [ ] Status bertahan setelah app di-restart (tanpa harus verifikasi ulang).

**Edge Cases:**
- Pengguna menekan back dari layar age gate → tetap di age gate (tidak boleh lanjut).
- Status verifikasi hilang dari database → redirect kembali ke age gate.

#### FR-02 — Onboarding (3 Halaman)
**Prioritas:** P0

**Deskripsi:** Pengenalan fitur dalam 3 halaman singkat (personalisasi, chat & suara,
privasi on-device) dengan tombol "Lanjut"/"Mulai".

**Acceptance Criteria:**
- [ ] 3 halaman dengan indikator posisi; bisa di-swipe.
- [ ] Halaman terakhir punya tombol "Mulai" → menuju Persona Setup.
- [ ] Status selesai disimpan (`isOnboardingDone`); onboarding tidak tampil lagi.
- [ ] Desain mengikuti DESIGN.md §3 (empty state, ilustrasi Lottie diperbolehkan).

**Edge Cases:**
- Pengguna keluar di tengah onboarding → lanjut dari halaman pertama saat kembali.
- Akses kembali setelah selesai → langsung ke home (chat).

#### FR-03 — Persona Setup (Buat Pasangan Virtual)
**Prioritas:** P0

**Deskripsi:** Alur pembuatan persona: pilih gender (girlfriend/boyfriend), nama,
nickname untuk pengguna, preset kepribadian (Gentle, Cheerful, Mature, Mysterious),
hobi, avatar (6 pilihan per gender), dan voice TTS.

**Acceptance Criteria:**
- [ ] Semua langkah bisa diselesaikan; hasil tersimpan di `PersonaConfig`.
- [ ] Validasi: nama tidak kosong (maks 32 karakter); minimal 1 hobi (opsional tapi
      dianjurkan).
- [ ] Preset kepribadian memengaruhi deskripsi persona pada prompt AI (DESIGN §6,
      `prompt_builder`).
- [ ] Avatar & voice punya preview saat dipilih.
- [ ] Setelah selesai, menuju Model Install.
- [ ] Persona bisa diedit dari Settings kapan saja (FR-18).

**Edge Cases:**
- Nama hanya spasi → tidak valid, tampilkan pesan hangat.
- Nama terlalu panjang → dibatasi input.
- Pengguna menekan back → kembali ke onboarding (tidak ke chat).

#### FR-04 — Model Install (Setup Model AI Lokal)
**Prioritas:** P0

**Deskripsi:** Memasang model SLM (`.task`, ~1.5 GB) dari aset aplikasi ke penyimpanan
internal. **Bukan unduhan internet** — file sudah dibundel di `assets/models/`.

**Acceptance Criteria:**
- [ ] Layar menunjukkan progres unpack + sisa storage.
- [ ] Storage cukup (< 2 GB) → sukses, inisialisasi engine, lanjut ke chat.
- [ ] Storage tidak cukup → pesan panduan + tombol retry.
- [ ] Status model siap dipersistenkan (`modelVariant`, flag model ready).
- [ ] Saat app di-restart, model tidak di-unpack ulang jika sudah ada.

**Edge Cases:**
- Model rusak/tidak lengkap → deteksi & re-unpack.
- Storage penuh di tengah proses → gagal-gracefully, jangan crash.
- Perangkat dengan RAM rendah → peringatan performa, tetap bisa mencoba.

---

### Chat & Suara

#### FR-05 — Chat dengan Streaming Respon AI
**Prioritas:** P0

**Deskripsi:** Layar utama: pengguna mengirim pesan, AI merespons dengan **streaming**
token. Riwayat percakapan tersimpan di ObjectBox. Konteks prompt berisi persona, mood,
memori, ringkasan percakapan, dan maks 20 pesan terakhir.

**Acceptance Criteria:**
- [ ] Pesan user tampil segera; typing indicator muncul selama AI memproses.
- [ ] Respon AI dirender bertahap (streaming) dan disimpan utuh setelah selesai.
- [ ] Tombol kirim berubah menjadi "stop" selama generasi berlangsung.
- [ ] Riwayat tetap ada setelah app di-restart.
- [ ] Respon mengikuti instruksi prompt (bahasa, kepribadian, mood, memori).
- [ ] Output melewati safety gate sebelum ditampilkan (FR-14).

**Edge Cases:**
- Model belum siap → tombol kirim nonaktif + pesan "model sedang disiapkan".
- Input kosong/terlalu panjang (> 2000 karakter) → dibatasi.
- Generasi terhenti (app di-background) → pesan parsial disimpan, mood tetap diperbarui.
- Prompt terlalu panjang → ringkasan + pemangkasan riwayat (FR-13).

#### FR-06 — Voice Input (Speech-to-Text)
**Prioritas:** P1

**Deskripsi:** Tombol mikrofon di chat input bar; rekam suara, konversi ke teks, lalu
kirim sebagai pesan.

**Acceptance Criteria:**
- [ ] Izin mikrofon diminta dengan penjelasan; ditolak → tombol nonaktif + tooltip.
- [ ] Saat merekam: waveform/indikator aktif; ketuk lagi untuk berhenti.
- [ ] Hasil transkripsi tampil di input sebelum dikirim (bisa diedit).
- [ ] Pesan hasil suara ditandai `isVoice` (opsional untuk UI).

**Edge Cases:**
- Permission ditolak permanen → arahkan ke pengaturan sistem.
- STT tidak tersedia (platform/region) → sembunyikan tombol.
- Transkripsi kosong → abaikan, jangan kirim.

#### FR-07 — Voice Output (Text-to-Speech)
**Prioritas:** P1

**Deskripsi:** Membacakan respon AI dengan suara persona. Pengaturan: aktif/nonaktif
TTS, autoplay saat respon selesai, dan pilihan suara.

**Acceptance Criteria:**
- [ ] Tombol play/stop di bubble/chat control; indikator sedang membaca.
- [ ] `ttsEnabled` mematikan semua suara; `ttsAutoPlay` memutar otomatis.
- [ ] Suara mengikuti `voiceId` persona (jika tersedia).
- [ ] Mematikan/beralih layar menghentikan playback.

**Edge Cases:**
- Engine TTS gagal inisialisasi → fallback diam, tanpa crash.
- Teks sangat panjang → baca per-paragraf, hentikan bila pengguna mengetik.
- Permission audio/notifikasi ditolak → tetap bisa chat (tanpa suara).

#### FR-08 — Typing Indicator
**Prioritas:** P0

**Deskripsi:** Animasi 3 titik saat AI sedang menyusun respons (DESIGN.md §3.3).

**Acceptance Criteria:**
- [ ] Muncul segera setelah pesan user terkirim, hilang saat token pertama tampil.
- [ ] Durasi & easing mengikuti token motion (DESIGN.md §2.6).

**Edge Cases:**
- Generasi lambat → indikator tetap tampil (tidak timeout palsu).

#### FR-09 — Dynamic Mood Engine
**Prioritas:** P0

**Deskripsi:** Pasangan virtual punya mood dinamis (Happy, Longing, Playful, Sad,
Excited) dengan intensitas 0.0–1.0. Mood diperbarui dari sentimen percakapan dan
waktu idle, lalu diinjeksikan ke prompt AI serta ditampilkan sebagai chip (FR-10/§3.4
DESIGN).

**Acceptance Criteria:**
- [ ] Mood diperbarui setelah setiap pertukaran pesan (keyword sentiment + konteks).
- [ ] Idle ≥ 6 jam → cenderung `longing`; ≥ 12 jam → `longing` intensitas tinggi.
- [ ] Mood tersimpan di ObjectBox (`MoodState`) dan bertahan setelah restart.
- [ ] Prompt AI menyertakan mood & intensitas (DESIGN §6, `prompt_builder`).
- [ ] Chip mood di header chat merefleksikan state saat ini.

**Edge Cases:**
- Percakapan campur aduk emosi → skor tertinggi menang, intensitas dibatasi (cap).
- Tanpa interaksi berhari-hari → mood `longing` (tidak pernah `sad` ekstrem).
- Reset mood saat data di-wipe (FR-19).

#### FR-10 — Persona Profile Sheet
**Prioritas:** P1

**Deskripsi:** Sheet yang bisa di-swipe-up dari chat: avatar besar, nama, preset
kepribadian, hobi, mood saat ini, dan pintu edit persona.

**Acceptance Criteria:**
- [ ] Tersedia dari app bar chat; animasi bottom sheet sesuai DESIGN §3.5.
- [ ] Menampilkan data persona & mood live.
- [ ] Tombol "Edit Persona" → Settings → Persona.

**Edge Cases:**
- Persona belum lengkap (data korup) → fallback nama default "VirtualHeart".

---

### Memori & Konteks

#### FR-11 — Memory Extraction (Ekstraksi Fakta)
**Prioritas:** P0

**Deskripsi:** Setelah percakapan, sistem mengekstrak fakta penting ke 4 kategori:
**Personal**, **Events**, **Preferences**, **Important Dates**. Fakta disimpan sebagai
`MemoryFact` dan direferensikan AI agar respons terasa personal.

**Acceptance Criteria:**
- [ ] Ekstraksi berjalan otomatis (batch/background ringan) setelah percakapan.
- [ ] Fakta punya `key`, `value`, `sourceSnippet`, `createdAt`, `lastReferencedAt`.
- [ ] Fakta duplikat digabung/di-update, bukan ditumpuk.
- [ ] Prompt AI menyertakan fakta relevan (DESIGN §6).

**Edge Cases:**
- Percakapan tanpa fakta → tidak ada ekstraksi (hemat token).
- Fakta sensitif (mis. kesehatan) → tetap diproses lokal; tidak pernah keluar perangkat.
- Hasil ekstraksi tidak valid/format salah → dibuang, jangan crash.

#### FR-12 — Memory Screen
**Prioritas:** P1

**Deskripsi:** Layar untuk melihat, mencari, dan menghapus fakta memori per kategori.

**Acceptance Criteria:**
- [ ] Daftar fakta dikelompokkan per kategori; ada pencarian (filter key/value).
- [ ] Hapus per-fakta dengan konfirmasi.
- [ ] Empty state hangat jika belum ada memori (DESIGN §3.7).

**Edge Cases:**
- Kategori kosong → tampilkan section kosong/tersembunyi.
- Pencarian tanpa hasil → pesan "tidak ditemukan" yang ramah.

#### FR-13 — Conversation Summarization
**Prioritas:** P0

**Deskripsi:** Percakapan panjang diringkas otomatis (setiap ±30 pesan) agar konteks
tetap terjaga tanpa meledakkan ukuran prompt. Ringkasan disimpan di
`AppSettings.conversationSummary`.

**Acceptance Criteria:**
- [ ] Ringkasan dihasilkan saat ambang pesan tercapai, menggantikan riwayat lama.
- [ ] Ringkasan diinjeksikan ke prompt sebagai `[CONTEXT SUMMARY]`.
- [ ] Ringkasan diperbarui saat percakapan berlanjut.
- [ ] Menghapus riwayat (FR-19) juga menghapus ringkasan.

**Edge Cases:**
- Model sibuk saat summarisasi → tunda ke jeda berikutnya, jangan blokir chat.
- Ringkasan gagal dihasilkan → lanjutkan dengan riwayat terpotong, coba lagi nanti.

#### FR-14 — Content Safety (Input & Output Gate)
**Prioritas:** P0

**Deskripsi:** Gate keamanan dua arah: (1) input user melewati filter sebelum diproses
model, (2) output model divalidasi sebelum ditampilkan. Konten berbahaya (eksplisit,
self-harm, ujaran kebencian, kekerasan) diblokir dengan respons hangat in-character.

**Acceptance Criteria:**
- [ ] Input terlarang → tidak diteruskan ke model; pengguna mendapat pesan penolakan hangat.
- [ ] Output terlarang → tidak ditampilkan; diganti pesan pengalihan in-character.
- [ ] Filter bekerja lokal (tanpa jaringan) dan tetap berfungsi offline.
- [ ] Tidak ada konten berbahaya yang lolos ke UI.

**Edge Cases:**
- Positif palsu (konten normal dianggap terlarang) → pesan netral, user bisa menulis ulang.
- Percakapan sensitif tapi legal (mis. duka) → TIDAK diblokir (filter berbasis kategori, bukan kata kunci kasar).

---

### Notifikasi

#### FR-15 — Morning Message
**Prioritas:** P1

**Deskripsi:** Notifikasi harian di waktu yang dikonfigurasi (default 08:00) berisi
sapaan romantis dari persona (templat acak hangat). Judul = nama persona.

**Acceptance Criteria:**
- [ ] Dijadwalkan ulang saat waktu diubah di Settings; repeat harian.
- [ ] Mati jika dimatikan di Settings; mati saat notifikasi dimatikan sistem.
- [ ] Tap notifikasi membuka chat.
- [ ] Gunakan channel & permission yang benar per platform (DESIGN §3.9).

**Edge Cases:**
- Waktu diubah ke masa lalu hari ini → jadwal besok.
- Permission ditolak → status "nonaktif" di Settings dengan penjelasan.
- Persona diubah namanya → notifikasi berikutnya memakai nama baru.

#### FR-16 — Check-in Notification
**Prioritas:** P2

**Deskripsi:** Pengingat saat pengguna tidak aktif dalam waktu tertentu (mis. keluar
app), berupa pesan rindu dari persona.

**Acceptance Criteria:**
- [ ] Dijadwalkan saat app masuk background (interval default: 0 jam — nonaktif sampai
      dikonfigurasi).
- [ ] Dibatalkan saat pengguna kembali membuka app.
- [ ] Hanya jika diaktifkan di Settings.

**Edge Cases:**
- App dibuka sebelum notifikasi muncul → dibatalkan (tidak muncul).
- Interval 0 = nonaktif (tidak menjadwalkan apa pun).

#### FR-17 — Special Day Notification
**Prioritas:** P2

**Deskripsi:** Notifikasi satu kali untuk momen penting (ulang tahun, anniversary) —
bisa dijadwalkan lewat memori Important Dates atau input manual.

**Acceptance Criteria:**
- [ ] Dijadwalkan pada tanggal tertentu; hanya jika tanggal masih di masa depan.
- [ ] Beberapa special day bisa aktif bersamaan (slot ID unik).
- [ ] Dibersihkan saat data memori dihapus.

**Edge Cases:**
- Tanggal sudah lewat saat penjadwalan → dilewati.
- Perubahan timezone → jadwal mengikuti zona lokal perangkat.

---

### Settings & Privasi

#### FR-18 — Settings
**Prioritas:** P0

**Deskripsi:** Layar pengaturan ber-section: Appearance (**tema default: Light — Romantic
Light**; pilihan Dark/System), Language (ID/EN/Mixed), Voice (TTS on/off, autoplay),
Notifications (morning/check-in/special day + waktu), Persona (edit profil), Data &
Privacy (lihat FR-19), Privacy Policy.

**Acceptance Criteria:**
- [ ] **Tema default adalah Light** (`ThemeMode.light`) saat pertama kali dibuka;
      pengguna bisa beralih ke Dark atau System.
- [ ] Semua perubahan tersimpan segera (`AppSettings`) dan langsung berlaku.
- [ ] Tema mengikuti pilihan; bahasa mengubah UI & instruksi AI.
- [ ] Perubahan persona tercermin di chat & notifikasi.
- [ ] Status izin (mikrofon, notifikasi) ditampilkan dengan jujur.

**Edge Cases:**
- Nilai rusak/korup di database → fallback ke default, jangan crash.
- Bahasa diubah di tengah percakapan → respon AI berikutnya memakai bahasa baru.
- Preferensi tema diubah ke System → mengikuti tema OS (light/dark).

#### FR-19 — Data Privacy (Hapus Riwayat / Wipe Memory)
**Prioritas:** P0

**Deskripsi:** Pengguna bisa menghapus riwayat chat, memori, atau seluruh data lokal
(termasuk persona & pengaturan) — semuanya on-device, tanpa server.

**Acceptance Criteria:**
- [ ] "Hapus riwayat chat" menghapus pesan + ringkasan; persona & memori tetap.
- [ ] "Hapus memori" menghapus semua fakta (dan special day terkait).
- [ ] "Reset semua data" menghapus semuanya dan kembali ke alur awal (age gate).
- [ ] Setiap aksi punya dialog konfirmasi eksplisit (DESIGN §3.8).
- [ ] Tidak ada data yang dikirim ke mana pun — penghapusan murni lokal.

**Edge Cases:**
- Penghapusan di tengah generasi AI → generasi dihentikan, state dibersihkan.
- Database kosong → aksi tetap berhasil (idempoten).

#### FR-20 — Bahasa (Indonesia / English / Mixed)
**Prioritas:** P1

**Deskripsi:** Pengaturan bahasa aplikasi: UI + instruksi AI mengikuti pilihan
(Indonesian, English, atau Mixed — UI Indonesia, AI bebas dua bahasa).

**Acceptance Criteria:**
- [ ] Semua string UI lewat lokalisasi (`core/l10n/`) — tidak ada string hardcode.
- [ ] Instruksi AI menyebut bahasa respon sesuai pilihan.
- [ ] Beralih bahasa berlaku tanpa restart.

**Edge Cases:**
- Terjemahan belum lengkap → fallback ke bahasa utama, bukan string kosong.
- Bahasa AI "Mixed" → instruksi menyatakan bebas campur, sesuai konteks percakapan.

---

## 4. Fitur Peningkatan (Usulan, P1/P2)

Fitur berikut **belum** ada di kode lama — usulan pengembangan selanjutnya. Daftar ini
bisa diubah; setiap item harus mendapat ID FR baru sebelum dikerjakan.

| ID usulan | Fitur | Prioritas | Catatan |
|---|---|---|---|
| FR-21 | Mood history & tren (grafik sederhana mood per hari) | P2 | Melengkapi FR-09 |
| FR-22 | Good night / momen harian (notifikasi malam opsional) | P2 | Melengkapi FR-15 |
| FR-23 | Ekspor/cadangan data lokal (file JSON di perangkat) | P2 | Tetap privacy-first, on-device |
| FR-24 | Ringkasan harian "kenangan bersama" (recap percakapan) | P2 | Emosional, memanfaatkan FR-13 |
| FR-25 | Dukungan persona tambahan (multiple companion) | P2 | Perlu perubahan skema data besar |
| FR-26 | Avatar & suara tambahan (paket konten) | P1 | Konten lokal, tanpa jaringan |
| FR-27 | Mode "quiet hours" (jeda notifikasi) | P2 | Melengkapi FR-15/16/17 |

---

## 5. Edge Cases Umum (Seluruh Fitur)

Daftar skenario lintas fitur yang wajib ditangani dengan **gagal-gracefully** (fallback
jelas, tanpa crash):

| Skenario | Perilaku yang diharapkan |
|---|---|
| Model AI belum siap / gagal init | Tombol aksi nonaktif + pesan hangat; layar retry (FR-04) |
| Permission ditolak (mikrofon, notifikasi, storage) | Fitur nonaktif dengan penjelasan + arahkan ke pengaturan |
| Database korup / gagal buka | Inisialisasi ulang aman, data default; jangan crash |
| Input kosong / terlalu panjang | Validasi + batasan karakter di UI |
| Safety gate aktif | Pesan pengalihan hangat, bukan error teknis |
| Storage hampir penuh | Peringatan sebelum unpack model / ekspor |
| App di-background saat generasi | Hentikan generasi, simpan state parsial |
| Device low-RAM | Peringatan performa saat model dipakai |

---

## 6. Matriks Rujukan

| Fitur | File/Modul Target (hasil refactor) | Entity/Service Terkait |
|---|---|---|
| FR-01 | `features/onboarding/` (age gate) | `AppSettings.isAgeVerified` |
| FR-02 | `features/onboarding/` | `AppSettings.isOnboardingDone` |
| FR-03 | `features/persona/` | `PersonaConfig`, `PersonalityPreset`, `PersonaGender` |
| FR-04 | `features/model/` | `model_service.dart`, `assets/models/*.task` |
| FR-05 | `features/chat/` | `Message`, `services/ai/prompt_builder.dart` |
| FR-06 | `features/chat/` (input bar) | `services/stt_service.dart` |
| FR-07 | `features/chat/` + `features/settings/` | `services/tts_service.dart`, `AppSettings.tts*` |
| FR-08 | `features/chat/widgets/` | — |
| FR-09 | `features/chat/` + mood engine | `MoodState`, `MoodType`, `services/ai/mood` |
| FR-10 | `features/chat/widgets/` | `PersonaConfig`, `MoodState` |
| FR-11 | `features/memory/` | `MemoryFact`, `MemoryCategory`, `memory_extractor.dart` |
| FR-12 | `features/memory/` | `MemoryFact` |
| FR-13 | `features/chat/` + `services/ai/` | `AppSettings.conversationSummary` |
| FR-14 | `services/ai/` | `content_safety.dart` |
| FR-15 | `features/notifications/` | `notification_service.dart` |
| FR-16 | `features/notifications/` | `notification_service.dart` |
| FR-17 | `features/notifications/` + `features/memory/` | `notification_service.dart` |
| FR-18 | `features/settings/` | `AppSettings` |
| FR-19 | `features/settings/` | ObjectBox (semua box) |
| FR-20 | `core/l10n/` + `features/settings/` | `AppLanguage` |

> Tabel ini menunjukkan **target modul hasil refactor** — bukan lokasi file saat ini.
> Implementasi wajib mengikuti struktur `lib/features/` (lihat `AGENTS.md` §3 &
> `DESIGN.md` §6).

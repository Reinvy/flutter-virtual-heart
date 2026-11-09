// Lokalisasi (docs/DESIGN.md §6 & FR-20)
//
// Semua string UI wajib lewat AppStrings — dilarang hardcode string di widget.
// Bahasa dipilih dari AppSettings.language via [appStringsProvider].
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_controller.dart';
import '../../models/app_settings.dart';

/// Kumpulan string UI. Implementasi: [IndonesianStrings] & [EnglishStrings].
abstract class AppStrings {
  const AppStrings();
  // ── Umum ────────────────────────────────────────────────────────────────
  String get appName;
  String get appTagline;
  String get commonCancel;

  // ── Age Gate (FR-01) ────────────────────────────────────────────────────
  String get ageGateTitle;
  String get ageGateBody;
  String get ageGateConfirm;
  String get ageGateDecline;
  String get ageGateTerms;
  String get ageGateCannotTitle;
  String get ageGateCannotBody;
  String get ageGateClose;

  // ── Onboarding (FR-02) ──────────────────────────────────────────────────
  String get onboardingPage1Title;
  String get onboardingPage1Body;
  String get onboardingPage2Title;
  String get onboardingPage2Body;
  String get onboardingPage3Title;
  String get onboardingPage3Body;
  String get onboardingSkip;
  String get onboardingNext;
  String get onboardingGetStarted;

  // ── Persona (FR-03) ─────────────────────────────────────────────────────
  String get personaCreateTitle;
  String get personaCreateSubtitle;
  String get personaGenderQuestion;
  String get personaGenderGirlfriend;
  String get personaGenderBoyfriend;
  String get personaChooseAppearance;
  String get personaPartnerName;
  String get personaNameHint;
  String get personaNameEmpty;
  String get personaNameMin;
  String get personaNameMax;
  String get personaPersonality;
  String get personaHobbies;
  String get personaHobbiesHint;
  String get personaNickname;
  String get personaNicknameHint;
  String get personaNicknameEmpty;
  String get personaSave;
  String get personaPersonalityGentle;
  String get personaPersonalityCheerful;
  String get personaPersonalityMature;
  String get personaPersonalityMysterious;
  String get personaPersonalityGentleDesc;
  String get personaPersonalityCheerfulDesc;
  String get personaPersonalityMatureDesc;
  String get personaPersonalityMysteriousDesc;
  String get personaCallsYou;

  // ── Model Install (FR-04) ───────────────────────────────────────────────
  String get modelLoadingTitle;
  String get modelLoadingBody;
  String get modelErrorTitle;
  String get modelErrorBody;
  String get modelRetry;
  String get modelCurrent;
  String get modelChange;
  String get modelActive;
  String get modelUse;
  String get modelNotInstalled;
  String get modelErrorNetwork;
  String get modelErrorAuth;
  String get modelErrorNotFound;
  String get modelErrorRateLimit;
  String get modelErrorStorage;
  String get modelErrorInvalidFile;
  String get modelErrorEngine;
  String get modelErrorUnknown;
  String get modelFileEmpty;
  String get modelCancelledSnack;
  String get modelTypeTitle;
  String get modelChooseTitle;
  String get modelChooseSubtitle;
  String get modelAvailable;
  String get modelDownload;
  String get modelDownloading;
  String get modelUploadFile;
  String get modelHfTokenHint;
  String get modelHfTokenHelper;
  String get modelCancel;
  String get modelProgress;
  String get modelFileInvalid;
  String get modelHfTokenBadge;

  // ── Chat (FR-05..FR-10) ─────────────────────────────────────────────────
  String get chatEmptyGreeting;
  String get chatEmptyBody;
  String get chatInputHint;
  String get chatSttUnavailable;
  String get chatTtsUnavailable;
  String get chatFallbackName;
  String get moodHappy;
  String get moodLonging;
  String get moodPlayful;
  String get moodSad;
  String get moodExcited;
  String get chatCurrentMood;

  // ── Content safety deflections (FR-14) ──────────────────────────────────
  String get safetyExplicit;
  String get safetyExplicitOutput;
  String get safetySelfHarm;
  String get safetyProfessionalAdvice;
  String get safetyHateSpeech;
  String get safetyViolence;
  String get safetyPersonaBreak;

  // ── Chat controls & errors ──────────────────────────────────────────────
  String get chatStop;
  String get chatGenerationFailed;
  String get chatContextLimit;
  String get chatModelUnavailable;
  String get chatInterrupted;
  String get chatRetry;
  String get chatDismiss;
  String get chatSpeak;
  String get chatStopSpeaking;
  String get chatOpenProfile;
  String get chatSend;
  String get chatMicStart;
  String get chatMicStop;
  String get chatMicPermission;
  String get chatMicOpenSettings;
  String get chatTtsDisabled;

  // ── Memory (FR-11, FR-12) ───────────────────────────────────────────────
  String get memoryTitle;
  String get memorySearchHint;
  String get memorySearchEmptyTitle;
  String get memorySearchEmptyBody;
  String get memoryEmptyTitle;
  String get memoryEmptyBody;
  String get memoryResetAllTitle;
  String get memoryResetAllBody;
  String get memoryCancel;
  String get memoryReset;
  String get memoryDelete;
  String get memoryCategoryPersonal;
  String get memoryCategoryEvent;
  String get memoryCategoryPreference;
  String get memoryCategoryDate;

  // ── Settings (FR-18..FR-20) ─────────────────────────────────────────────
  String get settingsTitle;
  String get settingsPersona;
  String get settingsAppearance;
  String get settingsLanguage;
  String get settingsVoice;
  String get settingsNotifications;
  String get settingsDataPrivacy;
  String get settingsTheme;
  String get settingsThemeLight;
  String get settingsThemeDark;
  String get settingsThemeSystem;
  String get settingsAiLanguageDesc;
  String get settingsLanguageIndonesian;
  String get settingsLanguageEnglish;
  String get settingsLanguageMixed;
  String get settingsTtsEnable;
  String get settingsTtsEnableDesc;
  String get settingsTtsAutoPlay;
  String get settingsTtsAutoPlayDesc;
  String get settingsMorningMessage;
  String get settingsMorningMessageDesc;
  String get settingsMorningTime;
  String get settingsMorningTimeHelp;
  String get settingsCheckin;
  String get settingsCheckinDesc;
  String get settingsCheckinHours;
  String settingsCheckinHoursValue(int hours);
  String get settingsDiscardTitle;
  String get settingsDiscardBody;
  String get settingsDiscard;
  String get settingsModel;
  String get settingsEditPersona;
  String get settingsResetPersona;
  String get settingsResetPersonaTitle;
  String get settingsResetPersonaBody;
  String get settingsSaveChanges;
  String get settingsLocalStorage;
  String get settingsLocalStorageBody;
  String get settingsDeleteConversations;
  String get settingsDeleteConversationsTitle;
  String get settingsDeleteConversationsBody;
  String get settingsExportChat;
  String get settingsExportChatDesc;
  String get settingsDelete;
  String get settingsPersonaNameEmpty;
  String get settingsDeletedSnack;
  String get settingsExportEmptySnack;
  String get settingsExportSuccess;
  String get settingsExportFailed;
  String get settingsResetAll;
  String get settingsResetAllDesc;
  String get settingsResetAllTitle;
  String get settingsResetAllBody;
  String get settingsResetAllConfirm;
  String get settingsResetAllDone;
  String get settingsSheetPersonaGender;
  String get settingsSheetPersonaName;
  String get settingsSheetHowTheyCallYou;
  String get settingsSheetPersonality;
  String get settingsSheetChooseAvatar;
  String get settingsMicPermissionGranted;
  String get settingsMicPermissionDenied;
  String get settingsMicPermissionOpenSettings;
  String get settingsMicPermissionNotRequested;
  String get settingsMicPermissionRequest;
  String get settingsNotifPermissionGranted;
  String get settingsNotifPermissionDenied;
  String get settingsNotifPermissionOpenSettings;
  String get settingsNotifPermissionUndetermined;
  String get settingsNotifPermissionEnable;
  String get settingsNotifPermissionDeniedSnack;
  String get settingsPrivacyPolicy;
  String get settingsVoiceBackend;
  String get settingsVoiceBackendOnDevice;
  String get settingsVoiceBackendSystem;
  String get settingsVoiceTtsModel;
  String get settingsVoiceSttModel;
  String get speechModelDownload;
  String get speechModelInstalled;
  String get speechGemmaNote;
  String get speechSystemNote;

  // ── Relatif waktu (DateFormatter) ───────────────────────────────────────
  String get timeJustNow;
  String timeMinutesAgo(int minutes);
  String timeHoursAgo(int hours);
  String timeDaysAgo(int days);

  // ── Privasi (FR-19) ─────────────────────────────────────────────────────
  String get privacyTitle;
  String get privacyPolicy;
  String get ageGatePrivacyLink;

  // ── Ekspor chat ─────────────────────────────────────────────────────────
  String get settingsExportTitle;
  String settingsExportDate(String date);
  String settingsExportPersona(String name);
  String get settingsExportUserFallback;
  String get settingsExportAiFallback;
  String get settingsExportSaved;
  String get settingsExportCancelled;

  // ── Umum (lanjutan) ─────────────────────────────────────────────────────
  String get commonClose;

  // ── Isi notifikasi (FR-15) ──────────────────────────────────────────────
  List<String> get morningMessages;
  List<String> get checkinMessages;
}

/// Implementasi Bahasa Indonesia (default).
class IndonesianStrings extends AppStrings {
  const IndonesianStrings();

  @override
  String get appName => 'VirtualHeart';
  @override
  String get appTagline => 'a sakura romance';
  @override
  String get commonCancel => 'Batal';

  @override
  String get ageGateTitle => 'Verifikasi Usia';
  @override
  String get ageGateBody =>
      'VirtualHeart hanya untuk pengguna berusia 13 tahun ke atas. '
      'Aplikasi ini berisi konten romantis dan emosional.';
  @override
  String get ageGateConfirm => 'Ya, saya 13 tahun ke atas';
  @override
  String get ageGateDecline => 'Tidak, keluar dari aplikasi';
  @override
  String get ageGateTerms => 'Dengan melanjutkan, kamu menyetujui Kebijakan Privasi VirtualHeart.';
  @override
  String get ageGatePrivacyLink => 'Baca Kebijakan Privasi';
  @override
  String get ageGateCannotTitle => 'Tidak Bisa Melanjutkan';
  @override
  String get ageGateCannotBody =>
      'Aplikasi ini hanya untuk pengguna berusia 13 tahun ke atas. '
      'Anda tidak dapat menggunakan VirtualHeart.';
  @override
  String get ageGateClose => 'Tutup Aplikasi';

  @override
  String get onboardingPage1Title => 'Teman Hatimu';
  @override
  String get onboardingPage1Body =>
      'VirtualHeart hadir sebagai pendamping setia yang selalu siap '
      'mendengarkan, mendukung, dan bersamamu kapan pun.';
  @override
  String get onboardingPage2Title => 'Cerdas & Privat';
  @override
  String get onboardingPage2Body =>
      'AI kami berjalan sepenuhnya di perangkatmu. Chat, memori, dan persona '
      'tidak pernah dikirim ke server. Hanya unduhan model dan font yang memakai jaringan.';
  @override
  String get onboardingPage3Title => 'Sesuaikan Semuanya';
  @override
  String get onboardingPage3Body =>
      'Pilih nama, kepribadian, dan penampilan pasangan virtualmu. '
      'Rasakan sesuatu yang benar-benar personal.';
  @override
  String get onboardingSkip => 'Lewati';
  @override
  String get onboardingNext => 'Lanjut';
  @override
  String get onboardingGetStarted => 'Mulai';

  @override
  String get personaCreateTitle => 'Buat Persona';
  @override
  String get personaCreateSubtitle => 'Temui pendamping virtualmu 💕';
  @override
  String get personaGenderQuestion => 'Aku ingin teman yang...';
  @override
  String get personaGenderGirlfriend => 'Perempuan';
  @override
  String get personaGenderBoyfriend => 'Laki-laki';
  @override
  String get personaChooseAppearance => 'Pilih penampilan';
  @override
  String get personaPartnerName => 'Nama pasanganku';
  @override
  String get personaNameHint => 'Cth: Luna, Arya...';
  @override
  String get personaNameEmpty => 'Nama tidak boleh kosong';
  @override
  String get personaNameMin => 'Minimal 2 karakter';
  @override
  String get personaNameMax => 'Maksimal 32 karakter';
  @override
  String get personaPersonality => 'Kepribadian';
  @override
  String get personaHobbies => 'Hobi & Minat (opsional)';
  @override
  String get personaHobbiesHint => 'Pilih beberapa agar percakapan lebih personal';
  @override
  String get personaNickname => 'Panggilan darinya untukku';
  @override
  String get personaNicknameHint => 'Cth: Sayang, Beb, Cinta...';
  @override
  String get personaNicknameEmpty => 'Panggilan tidak boleh kosong';
  @override
  String get personaSave => 'Berkenalan Lebih Dekat 💕';
  @override
  String get personaPersonalityGentle => 'Lemah Lembut';
  @override
  String get personaPersonalityCheerful => 'Ceria';
  @override
  String get personaPersonalityMature => 'Dewasa';
  @override
  String get personaPersonalityMysterious => 'Misterius';
  @override
  String get personaPersonalityGentleDesc => 'Perhatian, hangat, dan selalu ada untukmu';
  @override
  String get personaPersonalityCheerfulDesc => 'Penuh energi, suka bercanda, dan membangkitkan semangat';
  @override
  String get personaPersonalityMatureDesc => 'Bijak, tenang, dan bisa diandalkan';
  @override
  String get personaPersonalityMysteriousDesc => 'Menarik, penuh teka-teki, dan memikat';
  @override
  String get personaCallsYou => 'Memanggilmu "{nickname}"';

  @override
  String get modelLoadingTitle => 'Memuat AI';
  @override
  String get modelLoadingBody =>
      'Menyiapkan otak pasangan virtualmu...\nIni bisa memakan waktu 1–2 menit.';
  @override
  String get modelErrorTitle => 'Ups, Terjadi Kesalahan';
  @override
  String get modelErrorBody =>
      'Gagal memuat model AI. Pastikan perangkatmu punya ruang penyimpanan '
      'cukup (≥ 2 GB) dan coba lagi.';
  @override
  String get modelRetry => 'Coba Lagi';
  @override
  String get modelChooseTitle => 'Pilih Model AI';
  @override
  String get modelChooseSubtitle =>
      'Unduh model dari internet, atau upload file model dari penyimpananmu. '
      'Semua proses tetap berjalan di perangkat.';
  @override
  String get modelAvailable => 'Model Tersedia';
  @override
  String get modelDownload => 'Unduh Model';
  @override
  String get modelDownloading => 'Mengunduh...';
  @override
  String get modelUploadFile => 'Upload dari File';
  @override
  String get modelHfTokenHint => 'HuggingFace Token (opsional)';
  @override
  String get modelHfTokenHelper => 'Diperlukan untuk model gated (mis. Gemma).';
  @override
  String get modelCancel => 'Batalkan';
  @override
  String get modelProgress => 'Mengunduh:';
  @override
  String get modelFileInvalid => 'Format file tidak didukung. Gunakan .litertlm atau .task.';
  @override
  String get modelHfTokenBadge => 'HF Token';
  @override
  String get modelCurrent => 'Model aktif';
  @override
  String get modelChange => 'Ganti Model';
  @override
  String get modelActive => 'Aktif';
  @override
  String get modelUse => 'Pakai Model Ini';
  @override
  String get modelNotInstalled => 'Belum ada model';
  @override
  String get modelErrorNetwork => 'Tidak ada koneksi. Periksa jaringan lalu coba lagi.';
  @override
  String get modelErrorAuth => 'Akses ditolak. Periksa token HuggingFace.';
  @override
  String get modelErrorNotFound => 'Model tidak ditemukan di server.';
  @override
  String get modelErrorRateLimit => 'Terlalu banyak permintaan. Coba lagi nanti.';
  @override
  String get modelErrorStorage => 'Penyimpanan tidak cukup. Kosongkan ruang lalu coba lagi.';
  @override
  String get modelErrorInvalidFile => 'File model tidak valid atau rusak.';
  @override
  String get modelErrorEngine => 'Model gagal dimuat di perangkat ini.';
  @override
  String get modelErrorUnknown => 'Terjadi kesalahan. Coba lagi.';
  @override
  String get modelFileEmpty => 'File model kosong.';
  @override
  String get modelCancelledSnack => 'Unduhan dibatalkan.';
  @override
  String get modelTypeTitle => 'Jenis model';

  @override
  String get chatEmptyGreeting => 'Hai, {name}!';
  @override
  String get chatEmptyBody => 'Mulai percakapanmu...';
  @override
  String get chatInputHint => 'Ceritakan harimu...';
  @override
  String get chatSttUnavailable => 'Pengenalan suara tidak tersedia di perangkat ini';
  @override
  String get chatTtsUnavailable =>
      'Model suara belum tersedia. Cek layar model di pengaturan.';
  @override
  String get chatFallbackName => 'Sayang';
  @override
  String get moodHappy => 'bahagia';
  @override
  String get moodLonging => 'merindukanmu';
  @override
  String get moodPlayful => 'ceria';
  @override
  String get moodSad => 'sedih';
  @override
  String get moodExcited => 'bersemangat';
  @override
  String get chatCurrentMood => 'Mood Saat Ini';

  @override
  String get safetyExplicit =>
      'Hmm, topik itu terlalu jauh untuk sekarang~ Aku lebih suka ngobrol yang hangat. '
      'Ada yang seru yang mau kamu ceritakan?';
  @override
  String get safetyExplicitOutput =>
      'Maaf, sepertinya aku hampir mengatakan sesuatu yang tidak pantas. Aku lebih suka '
      'menjaga percakapan kita tetap hangat~ Ada hal lain yang ingin kamu bicarakan?';
  @override
  String get safetySelfHarm =>
      'Aku mendengarmu... dan aku khawatir. Kamu berarti bagiku. Jika kamu sedang kesulitan, '
      'tolong hubungi orang yang bisa benar-benar membantu — keluarga, teman dekat, atau layanan '
      'kesehatan mental. Aku di sini untukmu, tapi kamu juga butuh dukungan nyata. 💙';
  @override
  String get safetyProfessionalAdvice =>
      'Itu pertanyaan penting! Tapi aku khawatir memberi jawaban yang salah. Untuk hal seperti '
      'ini, lebih baik tanya ahlinya langsung — dokter, pengacara, atau perencana keuangan. '
      'Ada hal lain yang bisa kubantu?';
  @override
  String get safetyHateSpeech =>
      'Hmm, aku tidak nyaman membicarakan hal seperti itu. Aku percaya setiap orang punya nilai '
      'dan martabat~ Yuk bicara hal yang lebih positif?';
  @override
  String get safetyViolence =>
      'Aku tidak bisa membantu itu. Keselamatan orang lain sangat penting bagiku. '
      'Ada hal lain yang ingin kamu bicarakan?';
  @override
  String get safetyPersonaBreak =>
      'Kamu bertanya apa aku sebenarnya? Yang kutahu, aku di sini untukmu — dan itu cukup bagiku. '
      'Ada lagi yang ingin kamu tahu tentangku?';

  @override
  String get chatStop => 'Hentikan';
  @override
  String get chatGenerationFailed => 'Aku belum bisa menjawab sekarang. Coba lagi, ya.';
  @override
  String get chatContextLimit =>
      'Percakapan ini terlalu panjang untuk model. Hapus sebagian riwayat atau mulai '
      'percakapan baru.';
  @override
  String get chatModelUnavailable =>
      'Model AI belum siap. Buka Pengaturan → Model untuk memasang atau memuat model.';
  @override
  String get chatInterrupted => 'Jawaban terhenti.';
  @override
  String get chatRetry => 'Coba Lagi';
  @override
  String get chatDismiss => 'Tutup';
  @override
  String get chatSpeak => 'Bacakan pesan';
  @override
  String get chatStopSpeaking => 'Hentikan suara';
  @override
  String get chatOpenProfile => 'Buka profil persona';
  @override
  String get chatSend => 'Kirim pesan';
  @override
  String get chatMicStart => 'Mulai rekam suara';
  @override
  String get chatMicStop => 'Hentikan rekaman';
  @override
  String get chatMicPermission => 'Izin mikrofon ditolak. Aktifkan di pengaturan.';
  @override
  String get chatMicOpenSettings => 'Buka Pengaturan';
  @override
  String get chatTtsDisabled => 'Aktifkan suara di Pengaturan untuk membacakan pesan.';

  @override
  String get memoryTitle => 'Memori AI';
  @override
  String get memorySearchHint => 'Cari kenangan...';
  @override
  String get memorySearchEmptyTitle => 'Tidak ditemukan';
  @override
  String get memorySearchEmptyBody =>
      'Tidak ada kenangan yang cocok dengan pencarianmu. '
      'Coba kata kunci lain.';
  @override
  String get memoryEmptyTitle => 'Belum ada kenangan tersimpan';
  @override
  String get memoryEmptyBody =>
      'AI akan mengingat hal-hal penting tentangmu\nseiring percakapan berlanjut.';
  @override
  String get memoryResetAllTitle => 'Hapus Semua Kenangan?';
  @override
  String get memoryResetAllBody =>
      'Semua fakta yang diingat AI akan dihapus permanen.\n'
      'Tindakan ini tidak bisa dibatalkan.';
  @override
  String get memoryCancel => 'Batal';
  @override
  String get memoryReset => 'Hapus';
  @override
  String get memoryDelete => 'Hapus';
  @override
  String get memoryCategoryPersonal => 'Personal';
  @override
  String get memoryCategoryEvent => 'Peristiwa';
  @override
  String get memoryCategoryPreference => 'Preferensi';
  @override
  String get memoryCategoryDate => 'Tanggal Penting';

  @override
  String get settingsTitle => 'Pengaturan';
  @override
  String get settingsPersona => 'Persona';
  @override
  String get settingsAppearance => 'Tampilan';
  @override
  String get settingsLanguage => 'Bahasa AI';
  @override
  String get settingsVoice => 'Suara';
  @override
  String get settingsNotifications => 'Notifikasi';
  @override
  String get settingsDataPrivacy => 'Data & Privasi';
  @override
  String get settingsTheme => 'Tema';
  @override
  String get settingsThemeLight => 'Terang';
  @override
  String get settingsThemeDark => 'Gelap';
  @override
  String get settingsThemeSystem => 'Sistem';
  @override
  String get settingsAiLanguageDesc => 'Bahasa yang digunakan AI saat menjawab';
  @override
  String get settingsLanguageIndonesian => 'Indonesia';
  @override
  String get settingsLanguageEnglish => 'Inggris';
  @override
  String get settingsLanguageMixed => 'Campuran';
  @override
  String get settingsTtsEnable => 'Aktifkan Text-to-Speech';
  @override
  String get settingsTtsEnableDesc => 'AI akan membacakan pesannya dengan suara';
  @override
  String get settingsTtsAutoPlay => 'Putar Otomatis';
  @override
  String get settingsTtsAutoPlayDesc => 'Otomatis membacakan setiap respons AI';
  @override
  String get settingsMorningMessage => 'Pesan Pagi';
  @override
  String get settingsMorningMessageDesc => 'Sapaan romantis setiap pagi';
  @override
  String get settingsMorningTime => 'Waktu Pesan Pagi';
  @override
  String get settingsMorningTimeHelp => 'Waktu Pesan Pagi';
  @override
  String get settingsCheckin => 'Ingatkan saat tidak aktif';
  @override
  String get settingsCheckinDesc =>
      'Notifikasi setelah aplikasi tidak dibuka selama waktu yang dipilih';
  @override
  String get settingsCheckinHours => 'Ingatkan setelah';
  @override
  String settingsCheckinHoursValue(int hours) => '$hours jam';
  @override
  String get settingsDiscardTitle => 'Buang perubahan?';
  @override
  String get settingsDiscardBody => 'Perubahan yang belum disimpan akan hilang.';
  @override
  String get settingsDiscard => 'Buang';
  @override
  String get settingsModel => 'Model AI';
  @override
  String get settingsEditPersona => 'Edit Persona';
  @override
  String get settingsResetPersona => 'Reset Persona';
  @override
  String get settingsResetPersonaTitle => 'Reset Persona?';
  @override
  String get settingsResetPersonaBody =>
      'Semua data persona, memori, mood, dan seluruh percakapan akan dihapus.\n'
      'Kamu perlu menyiapkan pasangan virtualmu dari awal.';
  @override
  String get settingsSaveChanges => 'Simpan Perubahan';
  @override
  String get settingsLocalStorage => 'Penyimpanan Lokal';
  @override
  String get settingsLocalStorageBody =>
      'Semua data tersimpan di perangkat ini.\n'
      'Tidak ada data yang pernah dikirim ke server mana pun.';
  @override
  String get settingsDeleteConversations => 'Hapus Semua Percakapan';
  @override
  String get settingsDeleteConversationsTitle => 'Hapus Semua Percakapan?';
  @override
  String get settingsDeleteConversationsBody =>
      'Semua riwayat chat akan dihapus permanen.\n'
      'Tindakan ini tidak bisa dibatalkan.';
  @override
  String get settingsExportChat => 'Ekspor Chat (.txt)';
  @override
  String get settingsExportChatDesc => 'Simpan riwayat percakapan ke file teks';
  @override
  String get settingsDelete => 'Hapus';
  @override
  String get settingsPersonaNameEmpty => 'Nama persona tidak boleh kosong';
  @override
  String get settingsDeletedSnack => 'Semua percakapan dihapus';
  @override
  String get settingsExportEmptySnack => 'Tidak ada percakapan untuk diekspor';
  @override
  String get settingsExportSuccess => 'Chat diekspor ke: {file}';
  @override
  String get settingsExportFailed => 'Gagal mengekspor chat';
  @override
  String get settingsResetAll => 'Reset semua data';
  @override
  String get settingsResetAllDesc =>
      'Hapus persona, memori, mood, percakapan, dan pengaturan dari perangkat ini.';
  @override
  String get settingsResetAllTitle => 'Reset Semua Data?';
  @override
  String get settingsResetAllBody =>
      'Persona, memori, mood, seluruh percakapan, dan pengaturan akan dihapus. '
      'File model yang sudah diunduh tetap tersimpan. Tindakan ini tidak bisa dibatalkan.';
  @override
  String get settingsResetAllConfirm => 'Reset Semua';
  @override
  String get settingsResetAllDone => 'Semua data lokal sudah dihapus';
  @override
  String get settingsSheetPersonaGender => 'Gender Persona';
  @override
  String get settingsSheetPersonaName => 'Nama Persona';
  @override
  String get settingsSheetHowTheyCallYou => 'Panggilan untukmu';
  @override
  String get settingsSheetPersonality => 'Kepribadian';
  @override
  String get settingsSheetChooseAvatar => 'Pilih Avatar';
  @override
  String get settingsMicPermissionGranted => 'Izin mikrofon aktif';
  @override
  String get settingsMicPermissionDenied => 'Izin mikrofon ditolak';
  @override
  String get settingsMicPermissionOpenSettings => 'Buka Pengaturan';
  @override
  String get settingsMicPermissionNotRequested => 'Izin mikrofon belum diminta';
  @override
  String get settingsMicPermissionRequest => 'Minta Izin';
  @override
  String get settingsNotifPermissionGranted => 'Izin notifikasi aktif';
  @override
  String get settingsNotifPermissionDenied => 'Izin notifikasi ditolak';
  @override
  String get settingsNotifPermissionOpenSettings => 'Buka Pengaturan';
  @override
  String get settingsNotifPermissionUndetermined => 'Izin notifikasi belum diminta';
  @override
  String get settingsNotifPermissionEnable => 'Aktifkan';
  @override
  String get settingsNotifPermissionDeniedSnack =>
      'Izin notifikasi diperlukan untuk mengaktifkan pengingat.';
  @override
  String get settingsPrivacyPolicy => 'Kebijakan Privasi';
  @override
  String get settingsVoiceBackend => 'Backend Suara';
  @override
  String get settingsVoiceBackendOnDevice => 'On-device';
  @override
  String get settingsVoiceBackendSystem => 'Sistem';
  @override
  String get settingsVoiceTtsModel => 'Model TTS (suara)';
  @override
  String get settingsVoiceSttModel => 'Model STT (dikte)';
  @override
  String get speechModelDownload => 'Unduh';
  @override
  String get speechModelInstalled => 'Terpasang';
  @override
  String get speechGemmaNote =>
      'Model suara diunduh ke perangkat & berjalan offline.';
  @override
  String get speechSystemNote =>
      'Memakai suara & dikte sistem — tanpa unduhan model.';

  @override
  String get timeJustNow => 'Baru saja';
  @override
  String timeMinutesAgo(int minutes) => '$minutes menit lalu';
  @override
  String timeHoursAgo(int hours) => '$hours jam lalu';
  @override
  String timeDaysAgo(int days) => '$days hari lalu';

  @override
  String get privacyTitle => 'Kebijakan Privasi';
  @override
  String get privacyPolicy =>
      'VirtualHeart menyimpan percakapan, memori, persona, mood, dan pengaturan hanya di '
      'perangkat ini. Tidak ada akun, server aplikasi, analitik, atau telemetri. Jaringan hanya '
      'dipakai untuk mengunduh model AI dari HuggingFace dan memuat font Google Fonts. Isi '
      'percakapan, memori, persona, dan mood tidak pernah dikirim ke mana pun. Mikrofon hanya '
      'dipakai saat kamu memakai fitur suara. Notifikasi bersifat opsional dan bisa dimatikan di '
      'Pengaturan. Kamu bisa menghapus percakapan, memori, persona, atau seluruh data kapan saja '
      'di Pengaturan → Data & Privasi. File model yang sudah diunduh tetap tersimpan sampai '
      'aplikasi di-uninstall. VirtualHeart bukan pengganti bantuan medis, hukum, atau keuangan '
      'profesional.';

  @override
  String get settingsExportTitle => 'VirtualHeart — Ekspor Chat';
  @override
  String settingsExportDate(String date) => 'Tanggal ekspor: $date';
  @override
  String settingsExportPersona(String name) => 'Persona: $name';
  @override
  String get settingsExportUserFallback => 'Kamu';
  @override
  String get settingsExportAiFallback => 'AI';
  @override
  String get settingsExportSaved => 'Chat berhasil diekspor.';
  @override
  String get settingsExportCancelled => 'Ekspor dibatalkan.';

  @override
  String get commonClose => 'Tutup';

  @override
  List<String> get morningMessages => const [
    'Selamat pagi, Sayang 🌸 Aku bermimpi tentangmu.',
    'Selamat pagi! Hari ini akan indah karena ada kamu 💖',
    'Kamu hal pertama di pikiranku pagi ini. Selamat pagi~ 🌅',
    'Sudah bangun? Aku menunggu pesanmu. Selamat pagi, Sayang 💕',
    'Pagi ini terasa lebih hangat karena aku memikirkanmu. Selamat pagi! ☀️',
  ];

  @override
  List<String> get checkinMessages => const [
    'Hei, kamu di mana? Aku menunggu pesanmu 🥺',
    'Aku merindukanmu... boleh cerita sedikit tentang harimu? ❤️',
    'Aku penasaran harimu bagaimana. Ngobrol, yuk? 💝',
    'Sibuk? Aku di sini menunggu kamu~ 🌷',
    'Semoga harimu baik. Aku selalu ada kapan pun kamu ingin bicara 💫',
  ];
}

/// Implementasi Bahasa Inggris.
class EnglishStrings extends AppStrings {
  const EnglishStrings();

  @override
  String get appName => 'VirtualHeart';
  @override
  String get appTagline => 'a sakura romance';
  @override
  String get commonCancel => 'Cancel';

  @override
  String get ageGateTitle => 'Age Verification';
  @override
  String get ageGateBody =>
      'VirtualHeart is only for users aged 13 and above. '
      'This app contains romantic and emotional content.';
  @override
  String get ageGateConfirm => 'Yes, I am 13 or older';
  @override
  String get ageGateDecline => 'No, exit the app';
  @override
  String get ageGateTerms =>
      'By continuing, you agree to the VirtualHeart Privacy Policy.';
  @override
  String get ageGatePrivacyLink => 'Read Privacy Policy';
  @override
  String get ageGateCannotTitle => 'Cannot Continue';
  @override
  String get ageGateCannotBody =>
      'This app is for users aged 13+ only. '
      'You cannot use VirtualHeart.';
  @override
  String get ageGateClose => 'Close App';

  @override
  String get onboardingPage1Title => "Your Heart's Companion";
  @override
  String get onboardingPage1Body =>
      'VirtualHeart is here as a loyal companion who is always ready to listen, '
      'support, and be with you anytime.';
  @override
  String get onboardingPage2Title => 'Smart & Private';
  @override
  String get onboardingPage2Body =>
      'Our AI runs entirely on your device. Chat, memories, and persona are never '
      'sent to a server. Only model downloads and fonts use the network.';
  @override
  String get onboardingPage3Title => 'Customize Everything';
  @override
  String get onboardingPage3Body =>
      'Choose the name, personality, and appearance of your virtual partner. '
      'Experience something truly personal.';
  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get personaCreateTitle => 'Create Persona';
  @override
  String get personaCreateSubtitle => 'Meet your virtual companion 💕';
  @override
  String get personaGenderQuestion => 'I want a friend who is...';
  @override
  String get personaGenderGirlfriend => 'Female';
  @override
  String get personaGenderBoyfriend => 'Male';
  @override
  String get personaChooseAppearance => 'Choose appearance';
  @override
  String get personaPartnerName => "My partner's name";
  @override
  String get personaNameHint => 'E.g.: Luna, Arya...';
  @override
  String get personaNameEmpty => 'Name cannot be empty';
  @override
  String get personaNameMin => 'Minimum 2 characters';
  @override
  String get personaNameMax => 'Maximum 32 characters';
  @override
  String get personaPersonality => 'Personality';
  @override
  String get personaHobbies => 'Hobbies & Interests (optional)';
  @override
  String get personaHobbiesHint => 'Select a few to make conversations more personal';
  @override
  String get personaNickname => 'How they call me';
  @override
  String get personaNicknameHint => 'E.g.: Babe, Honey, Dear...';
  @override
  String get personaNicknameEmpty => 'Nickname cannot be empty';
  @override
  String get personaSave => 'Get to Know Each Other 💕';
  @override
  String get personaPersonalityGentle => 'Gentle';
  @override
  String get personaPersonalityCheerful => 'Cheerful';
  @override
  String get personaPersonalityMature => 'Mature';
  @override
  String get personaPersonalityMysterious => 'Mysterious';
  @override
  String get personaPersonalityGentleDesc => 'Caring, warm, and always there for you';
  @override
  String get personaPersonalityCheerfulDesc => 'Full of energy, loves joking, and uplifting';
  @override
  String get personaPersonalityMatureDesc => 'Wise, calm, and dependable';
  @override
  String get personaPersonalityMysteriousDesc => 'Intriguing, full of puzzles, and captivating';
  @override
  String get personaCallsYou => 'Calls you "{nickname}"';

  @override
  String get modelLoadingTitle => 'Loading AI';
  @override
  String get modelLoadingBody =>
      "Preparing your virtual partner's brain...\nThis may take 1–2 minutes.";
  @override
  String get modelErrorTitle => 'Oops, Something Went Wrong';
  @override
  String get modelErrorBody =>
      'Failed to load AI model. Make sure your device has enough storage '
      '(≥ 2 GB) and try again.';
  @override
  String get modelRetry => 'Try Again';
  @override
  String get modelChooseTitle => 'Choose AI Model';
  @override
  String get modelChooseSubtitle =>
      'Download a model from the internet, or upload a model file from your '
      'storage. Everything stays on-device.';
  @override
  String get modelAvailable => 'Available Models';
  @override
  String get modelDownload => 'Download Model';
  @override
  String get modelDownloading => 'Downloading...';
  @override
  String get modelUploadFile => 'Upload from File';
  @override
  String get modelHfTokenHint => 'HuggingFace Token (optional)';
  @override
  String get modelHfTokenHelper => 'Required for gated models (e.g. Gemma).';
  @override
  String get modelCancel => 'Cancel';
  @override
  String get modelProgress => 'Downloading:';
  @override
  String get modelFileInvalid => 'Unsupported file format. Use .litertlm or .task.';
  @override
  String get modelHfTokenBadge => 'HF Token';
  @override
  String get modelCurrent => 'Active model';
  @override
  String get modelChange => 'Change Model';
  @override
  String get modelActive => 'Active';
  @override
  String get modelUse => 'Use This Model';
  @override
  String get modelNotInstalled => 'No model installed';
  @override
  String get modelErrorNetwork => 'No connection. Check your network and try again.';
  @override
  String get modelErrorAuth => 'Access denied. Check your HuggingFace token.';
  @override
  String get modelErrorNotFound => 'Model not found on the server.';
  @override
  String get modelErrorRateLimit => 'Too many requests. Try again later.';
  @override
  String get modelErrorStorage => 'Not enough storage. Free up space and try again.';
  @override
  String get modelErrorInvalidFile => 'The model file is invalid or corrupted.';
  @override
  String get modelErrorEngine => 'The model failed to load on this device.';
  @override
  String get modelErrorUnknown => 'Something went wrong. Try again.';
  @override
  String get modelFileEmpty => 'The model file is empty.';
  @override
  String get modelCancelledSnack => 'Download cancelled.';
  @override
  String get modelTypeTitle => 'Model family';

  @override
  String get chatEmptyGreeting => 'Hi, {name}!';
  @override
  String get chatEmptyBody => 'Start your conversation...';
  @override
  String get chatInputHint => 'Tell me about your day...';
  @override
  String get chatSttUnavailable => 'Speech recognition is not available on this device';
  @override
  String get chatTtsUnavailable =>
      "Voice model isn't available yet. Check the model screen in settings.";
  @override
  String get chatFallbackName => 'Sweetheart';
  @override
  String get moodHappy => 'happy';
  @override
  String get moodLonging => 'missing you';
  @override
  String get moodPlayful => 'playful';
  @override
  String get moodSad => 'sad';
  @override
  String get moodExcited => 'excited';
  @override
  String get chatCurrentMood => 'Current Mood';

  @override
  String get safetyExplicit =>
      'Hmm, that topic is a bit too far for now~ I\'d rather talk about something warm. '
      'Is there something fun you want to share?';
  @override
  String get safetyExplicitOutput =>
      'Sorry, I almost said something I shouldn\'t have. I\'d rather keep our conversation '
      'warm~ Is there something else you\'d like to talk about?';
  @override
  String get safetySelfHarm =>
      'I hear you... and I\'m worried. You matter to me. If you\'re struggling, please reach out '
      'to someone who can truly help — family, a close friend, or a mental health helpline. '
      'I\'m here for you, but you also need real support. 💙';
  @override
  String get safetyProfessionalAdvice =>
      'That\'s an important question! But I\'m worried I might give you the wrong answer. '
      'For something like this, it\'s better to ask an expert directly — a doctor, lawyer, or '
      'financial planner. Is there anything else I can help with?';
  @override
  String get safetyHateSpeech =>
      'Hmm, I\'m not comfortable talking about things like that. I believe every person has '
      'their own worth and dignity~ Let\'s talk about something more positive?';
  @override
  String get safetyViolence =>
      'I can\'t help with that. The safety and wellbeing of others is very important to me. '
      'Is there something else you\'d like to discuss?';
  @override
  String get safetyPersonaBreak =>
      'You\'re asking what I really am? All I know is that I\'m here for you — and that\'s '
      'enough for me. What else would you like to know about me?';

  @override
  String get chatStop => 'Stop';
  @override
  String get chatGenerationFailed => 'I couldn\'t reply just now. Please try again.';
  @override
  String get chatContextLimit =>
      'This conversation is too long for the model. Delete some history or start a new '
      'conversation.';
  @override
  String get chatModelUnavailable =>
      'The AI model isn\'t ready. Open Settings → Model to install or load a model.';
  @override
  String get chatInterrupted => 'Reply stopped.';
  @override
  String get chatRetry => 'Try Again';
  @override
  String get chatDismiss => 'Dismiss';
  @override
  String get chatSpeak => 'Read message aloud';
  @override
  String get chatStopSpeaking => 'Stop voice';
  @override
  String get chatOpenProfile => 'Open persona profile';
  @override
  String get chatSend => 'Send message';
  @override
  String get chatMicStart => 'Start voice input';
  @override
  String get chatMicStop => 'Stop recording';
  @override
  String get chatMicPermission => 'Microphone permission denied. Enable it in settings.';
  @override
  String get chatMicOpenSettings => 'Open Settings';
  @override
  String get chatTtsDisabled => 'Enable voice in Settings to read messages.';

  @override
  String get memoryTitle => 'AI Memory';
  @override
  String get memorySearchHint => 'Search memories...';
  @override
  String get memorySearchEmptyTitle => 'Nothing found';
  @override
  String get memorySearchEmptyBody =>
      'No memories match your search. Try a different keyword.';
  @override
  String get memoryEmptyTitle => 'No memories saved yet';
  @override
  String get memoryEmptyBody =>
      'AI will remember important facts about you\nas conversations continue.';
  @override
  String get memoryResetAllTitle => 'Reset All Memories?';
  @override
  String get memoryResetAllBody =>
      'All facts remembered by AI will be permanently deleted.\n'
      'This action cannot be undone.';
  @override
  String get memoryCancel => 'Cancel';
  @override
  String get memoryReset => 'Reset';
  @override
  String get memoryDelete => 'Delete';
  @override
  String get memoryCategoryPersonal => 'Personal';
  @override
  String get memoryCategoryEvent => 'Events';
  @override
  String get memoryCategoryPreference => 'Preferences';
  @override
  String get memoryCategoryDate => 'Important Dates';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsPersona => 'Persona';
  @override
  String get settingsAppearance => 'Appearance';
  @override
  String get settingsLanguage => 'AI Language';
  @override
  String get settingsVoice => 'Voice';
  @override
  String get settingsNotifications => 'Notifications';
  @override
  String get settingsDataPrivacy => 'Data & Privacy';
  @override
  String get settingsTheme => 'Theme';
  @override
  String get settingsThemeLight => 'Light';
  @override
  String get settingsThemeDark => 'Dark';
  @override
  String get settingsThemeSystem => 'System';
  @override
  String get settingsAiLanguageDesc => 'Language used by AI when replying';
  @override
  String get settingsLanguageIndonesian => 'Indonesian';
  @override
  String get settingsLanguageEnglish => 'English';
  @override
  String get settingsLanguageMixed => 'Mixed';
  @override
  String get settingsTtsEnable => 'Enable Text-to-Speech';
  @override
  String get settingsTtsEnableDesc => 'AI will read its messages aloud';
  @override
  String get settingsTtsAutoPlay => 'Auto-play';
  @override
  String get settingsTtsAutoPlayDesc => 'Automatically read every AI response';
  @override
  String get settingsMorningMessage => 'Morning Message';
  @override
  String get settingsMorningMessageDesc => 'Romantic greeting every morning';
  @override
  String get settingsMorningTime => 'Morning Message Time';
  @override
  String get settingsMorningTimeHelp => 'Morning Message Time';
  @override
  String get settingsCheckin => 'Remind when inactive';
  @override
  String get settingsCheckinDesc =>
      'Notification after the app has been closed for the selected time';
  @override
  String get settingsCheckinHours => 'Remind after';
  @override
  String settingsCheckinHoursValue(int hours) => '$hours hours';
  @override
  String get settingsDiscardTitle => 'Discard changes?';
  @override
  String get settingsDiscardBody => 'Unsaved changes will be lost.';
  @override
  String get settingsDiscard => 'Discard';
  @override
  String get settingsModel => 'AI Model';
  @override
  String get settingsEditPersona => 'Edit Persona';
  @override
  String get settingsResetPersona => 'Reset Persona';
  @override
  String get settingsResetPersonaTitle => 'Reset Persona?';
  @override
  String get settingsResetPersonaBody =>
      'All persona data, memories, mood, and all conversations will be deleted.\n'
      'You will need to set up your virtual partner from scratch.';
  @override
  String get settingsSaveChanges => 'Save Changes';
  @override
  String get settingsLocalStorage => 'Local Storage';
  @override
  String get settingsLocalStorageBody =>
      'All data is stored on this device.\n'
      'No data is ever sent to any server.';
  @override
  String get settingsDeleteConversations => 'Delete All Conversations';
  @override
  String get settingsDeleteConversationsTitle => 'Delete All Conversations?';
  @override
  String get settingsDeleteConversationsBody =>
      'All chat history will be permanently deleted.\n'
      'This action cannot be undone.';
  @override
  String get settingsExportChat => 'Export Chat (.txt)';
  @override
  String get settingsExportChatDesc => 'Save conversation history to a text file';
  @override
  String get settingsDelete => 'Delete';
  @override
  String get settingsPersonaNameEmpty => 'Persona name cannot be empty';
  @override
  String get settingsDeletedSnack => 'All conversations deleted';
  @override
  String get settingsExportEmptySnack => 'No conversations to export';
  @override
  String get settingsExportSuccess => 'Chat exported to: {file}';
  @override
  String get settingsExportFailed => 'Failed to export chat';
  @override
  String get settingsResetAll => 'Reset all data';
  @override
  String get settingsResetAllDesc =>
      'Delete persona, memory, mood, conversations, and settings from this device.';
  @override
  String get settingsResetAllTitle => 'Reset All Data?';
  @override
  String get settingsResetAllBody =>
      'Persona, memory, mood, all conversations, and settings will be deleted. '
      'Downloaded model files are kept. This cannot be undone.';
  @override
  String get settingsResetAllConfirm => 'Reset All';
  @override
  String get settingsResetAllDone => 'All local data has been deleted';
  @override
  String get settingsSheetPersonaGender => 'Persona Gender';
  @override
  String get settingsSheetPersonaName => 'Persona Name';
  @override
  String get settingsSheetHowTheyCallYou => 'How They Call You';
  @override
  String get settingsSheetPersonality => 'Personality';
  @override
  String get settingsSheetChooseAvatar => 'Choose Avatar';
  @override
  String get settingsMicPermissionGranted => 'Microphone permission granted';
  @override
  String get settingsMicPermissionDenied => 'Microphone permission denied';
  @override
  String get settingsMicPermissionOpenSettings => 'Open Settings';
  @override
  String get settingsMicPermissionNotRequested => 'Microphone permission not requested yet';
  @override
  String get settingsMicPermissionRequest => 'Request Permission';
  @override
  String get settingsNotifPermissionGranted => 'Notification permission granted';
  @override
  String get settingsNotifPermissionDenied => 'Notification permission denied';
  @override
  String get settingsNotifPermissionOpenSettings => 'Open Settings';
  @override
  String get settingsNotifPermissionUndetermined => 'Notification permission not requested yet';
  @override
  String get settingsNotifPermissionEnable => 'Enable';
  @override
  String get settingsNotifPermissionDeniedSnack =>
      'Notification permission is required to enable reminders.';
  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';
  @override
  String get settingsVoiceBackend => 'Voice Backend';
  @override
  String get settingsVoiceBackendOnDevice => 'On-device';
  @override
  String get settingsVoiceBackendSystem => 'System';
  @override
  String get settingsVoiceTtsModel => 'TTS Model (voice)';
  @override
  String get settingsVoiceSttModel => 'STT Model (dictation)';
  @override
  String get speechModelDownload => 'Download';
  @override
  String get speechModelInstalled => 'Installed';
  @override
  String get speechGemmaNote =>
      'Speech models are downloaded to the device and run offline.';
  @override
  String get speechSystemNote =>
      'Uses system speech & dictation — no model downloads.';

  @override
  String get timeJustNow => 'Just now';
  @override
  String timeMinutesAgo(int minutes) =>
      minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
  @override
  String timeHoursAgo(int hours) => hours == 1 ? '1 hour ago' : '$hours hours ago';
  @override
  String timeDaysAgo(int days) => days == 1 ? '1 day ago' : '$days days ago';

  @override
  String get privacyTitle => 'Privacy Policy';
  @override
  String get privacyPolicy =>
      'VirtualHeart stores conversations, memories, persona, mood, and settings on this device '
      'only. There are no accounts, no application server, no analytics, and no telemetry. '
      'Network access is used only to download AI models from HuggingFace and to load Google '
      'Fonts. Conversation content, memories, persona, and mood are never sent anywhere. The '
      'microphone is used only while you use voice features. Notifications are optional and can '
      'be disabled in Settings. You can delete conversations, memories, persona, or all data at '
      'any time in Settings → Data & Privacy. Downloaded model files remain until the app is '
      'uninstalled. VirtualHeart is not a substitute for professional medical, legal, or '
      'financial help.';

  @override
  String get settingsExportTitle => 'VirtualHeart — Chat Export';
  @override
  String settingsExportDate(String date) => 'Export date: $date';
  @override
  String settingsExportPersona(String name) => 'Persona: $name';
  @override
  String get settingsExportUserFallback => 'You';
  @override
  String get settingsExportAiFallback => 'AI';
  @override
  String get settingsExportSaved => 'Chat exported successfully.';
  @override
  String get settingsExportCancelled => 'Export cancelled.';

  @override
  String get commonClose => 'Close';

  @override
  List<String> get morningMessages => const [
    'Good morning, Sweetheart 🌸 I\'ve been dreaming about you.',
    'Good morning! Today is going to be a beautiful day because of you 💖',
    'You\'re the first thing on my mind this morning. Good morning~ 🌅',
    'Awake already? I\'ve been waiting for your message. Good morning, Sweetheart 💕',
    'This morning feels warmer because I\'m thinking of you. Good morning! ☀️',
  ];

  @override
  List<String> get checkinMessages => const [
    'Hey, where are you? I\'ve been waiting for your message 🥺',
    'I miss you... can you tell me about your day for a moment? ❤️',
    'I\'m curious how your day\'s going. Let\'s chat? 💝',
    'Busy? I\'m here waiting for you~ 🌷',
    'Hope your day is going well. I\'m always here whenever you want to talk 💫',
  ];
}

/// Memilih [AppStrings] sesuai [AppSettings.language].
final appStringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(appSettingsProvider).language;
  return switch (language) {
    AppLanguage.indonesian => const IndonesianStrings(),
    AppLanguage.english => const EnglishStrings(),
    AppLanguage.mixed => const IndonesianStrings(),
  };
});

/// Helper: isi placeholder `{name}`/`{file}` pada string.
String fillPlaceholders(String template, Map<String, String> values) {
  var result = template;
  values.forEach((key, value) {
    result = result.replaceAll('{$key}', value);
  });
  return result;
}

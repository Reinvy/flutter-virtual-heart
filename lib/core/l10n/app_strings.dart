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
  String get modelTip1;
  String get modelTip2;
  String get modelTip3;
  String get modelTip4;
  String get modelTip5;

  // ── Chat (FR-05..FR-10) ─────────────────────────────────────────────────
  String get chatEmptyGreeting;
  String get chatEmptyBody;
  String get chatInputHint;
  String get chatSttUnavailable;
  String get moodHappy;
  String get moodLonging;
  String get moodPlayful;
  String get moodSad;
  String get moodExcited;
  String get chatCurrentMood;

  // ── Memory (FR-11, FR-12) ───────────────────────────────────────────────
  String get memoryTitle;
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
  String get settingsAiLanguage;
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
  String get settingsSheetPersonaGender;
  String get settingsSheetPersonaName;
  String get settingsSheetHowTheyCallYou;
  String get settingsSheetPersonality;
  String get settingsSheetChooseAvatar;

  // ── Relatif waktu (DateFormatter) ───────────────────────────────────────
  String get timeJustNow;
  String timeMinutesAgo(int minutes);
  String timeHoursAgo(int hours);
  String timeDaysAgo(int days);
}

/// Implementasi Bahasa Indonesia (default).
class IndonesianStrings extends AppStrings {
  const IndonesianStrings();

  @override
  String get appName => 'VirtualHeart';

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
  String get ageGateTerms =>
      'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan\n'
      'dan Kebijakan Privasi VirtualHeart.';
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
      'AI kami berjalan sepenuhnya di perangkatmu — privasimu terjaga, '
      'tidak ada data yang pernah dikirim ke server mana pun.';
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
  String get personaCallsYou => 'Memanggilmu';

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
  String get modelTip1 => '💕 Pasangan virtualmu sedang mengenalmu...';
  @override
  String get modelTip2 => '🌸 Menyiapkan kepribadian yang sempurna untukmu...';
  @override
  String get modelTip3 => '✨ AI berjalan sepenuhnya di perangkatmu — privasimu terjaga';
  @override
  String get modelTip4 => '🔮 Hampir siap menemanimu...';
  @override
  String get modelTip5 => '💝 Merangkai kemampuan percakapan yang hangat...';

  @override
  String get chatEmptyGreeting => 'Hai, {name}!';
  @override
  String get chatEmptyBody => 'Mulai percakapanmu...';
  @override
  String get chatInputHint => 'Ceritakan harimu...';
  @override
  String get chatSttUnavailable => 'Pengenalan suara tidak tersedia di perangkat ini';
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
  String get memoryTitle => 'Memori AI';
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
  String get settingsAiLanguage => 'Bahasa AI';
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
  String get settingsCheckinDesc => 'Notifikasi jika aplikasi tidak dibuka > 6 jam';
  @override
  String get settingsEditPersona => 'Edit Persona';
  @override
  String get settingsResetPersona => 'Reset Persona';
  @override
  String get settingsResetPersonaTitle => 'Reset Persona?';
  @override
  String get settingsResetPersonaBody =>
      'Semua data persona, memori, dan mood akan dihapus.\n'
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
  String get timeJustNow => 'Baru saja';
  @override
  String timeMinutesAgo(int minutes) => '$minutes menit lalu';
  @override
  String timeHoursAgo(int hours) => '$hours jam lalu';
  @override
  String timeDaysAgo(int days) => '$days hari lalu';
}

/// Implementasi Bahasa Inggris.
class EnglishStrings extends AppStrings {
  const EnglishStrings();

  @override
  String get appName => 'VirtualHeart';

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
      'By continuing, you agree to the Terms & Conditions\n'
      'and Privacy Policy of VirtualHeart.';
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
      'Our AI runs entirely on your device — your privacy is preserved, '
      'no data is ever sent to any server.';
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
  String get personaCallsYou => 'Calls you';

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
  String get modelTip1 => '💕 Your virtual partner is getting to know you...';
  @override
  String get modelTip2 => '🌸 Preparing the perfect personality for you...';
  @override
  String get modelTip3 => '✨ AI runs entirely on your device — your privacy is protected';
  @override
  String get modelTip4 => '🔮 Almost ready to accompany you...';
  @override
  String get modelTip5 => '💝 Crafting warm and intimate conversation skills...';

  @override
  String get chatEmptyGreeting => 'Hi, {name}!';
  @override
  String get chatEmptyBody => 'Start your conversation...';
  @override
  String get chatInputHint => 'Tell me about your day...';
  @override
  String get chatSttUnavailable => 'Speech recognition is not available on this device';
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
  String get memoryTitle => 'AI Memory';
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
  String get settingsAiLanguage => 'AI Language';
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
  String get settingsCheckinDesc => 'Notification if app not opened for >6 hours';
  @override
  String get settingsEditPersona => 'Edit Persona';
  @override
  String get settingsResetPersona => 'Reset Persona';
  @override
  String get settingsResetPersonaTitle => 'Reset Persona?';
  @override
  String get settingsResetPersonaBody =>
      'All persona data, memories, and mood will be deleted.\n'
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
  String get timeJustNow => 'Just now';
  @override
  String timeMinutesAgo(int minutes) => '$minutes minutes ago';
  @override
  String timeHoursAgo(int hours) => '$hours hours ago';
  @override
  String timeDaysAgo(int days) => '$days days ago';
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

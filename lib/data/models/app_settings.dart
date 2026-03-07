// TODO Phase 1.2: Add @Entity() ObjectBox annotation and run build_runner

enum AppTheme { dark, light, system }

enum AppLanguage { indonesian, english, mixed }

class AppSettings {
  int id = 0;
  AppTheme theme = AppTheme.dark;
  AppLanguage language = AppLanguage.indonesian;
  bool ttsEnabled = false;
  bool ttsAutoPlay = false;
  bool notificationMorningEnabled = false;
  String notificationMorningTime = '08:00';
  bool notificationCheckinEnabled = false;
  String modelVariant = 'gemma3-1b';
  bool isAgeVerified = false;
  bool isOnboardingDone = false;
  bool isPersonaSetup = false;
  String conversationSummary = '';
}

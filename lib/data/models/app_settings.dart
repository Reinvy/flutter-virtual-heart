import 'package:objectbox/objectbox.dart';

enum AppTheme { dark, light, system }

enum AppLanguage { indonesian, english, mixed }

@Entity()
class AppSettings {
  @Id()
  int id = 0;

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

  // Enum backing fields (stored as int index)
  int themeIndex = 0;
  int languageIndex = 0;

  AppTheme get theme => AppTheme.values[themeIndex];
  set theme(AppTheme value) => themeIndex = value.index;

  AppLanguage get language => AppLanguage.values[languageIndex];
  set language(AppLanguage value) => languageIndex = value.index;

  AppSettings({
    this.id = 0,
    AppTheme theme = AppTheme.dark,
    AppLanguage language = AppLanguage.indonesian,
    this.ttsEnabled = false,
    this.ttsAutoPlay = false,
    this.notificationMorningEnabled = false,
    this.notificationMorningTime = '08:00',
    this.notificationCheckinEnabled = false,
    this.modelVariant = 'gemma3-1b',
    this.isAgeVerified = false,
    this.isOnboardingDone = false,
    this.isPersonaSetup = false,
    this.conversationSummary = '',
  }) {
    themeIndex = theme.index;
    languageIndex = language.index;
  }
}

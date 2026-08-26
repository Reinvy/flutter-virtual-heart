// Entity ObjectBox — Pengaturan aplikasi (FR-18)
import 'package:objectbox/objectbox.dart';

enum AppThemeSetting { light, dark, system }

enum AppLanguage { indonesian, english, mixed }

@Entity()
class AppSettings {
  @Id()
  int id = 0;

  bool ttsEnabled = false;
  bool ttsAutoPlay = false;
  String ttsBackend = 'gemma'; // 'gemma' | 'system'
  String sttBackend = 'gemma'; // 'gemma' | 'system'
  String ttsModel = 'inflect'; // 'inflect' | 'matcha' | 'qwen3'
  String sttModel = 'moonshine';
  bool notificationMorningEnabled = false;
  String notificationMorningTime = '08:00';
  bool notificationCheckinEnabled = false;
  String modelVariant = 'qwen2.5-1.5b';
  String modelSource = ''; // '' | 'network' | 'file'
  String modelUrl = '';
  bool isAgeVerified = false;
  bool isOnboardingDone = false;
  bool isPersonaSetup = false;
  String conversationSummary = '';

  // Enum backing fields (stored as int index)
  int themeIndex = 0;
  int languageIndex = 0;

  AppThemeSetting get theme => AppThemeSetting.values[themeIndex];
  set theme(AppThemeSetting value) => themeIndex = value.index;

  AppLanguage get language => AppLanguage.values[languageIndex];
  set language(AppLanguage value) => languageIndex = value.index;

  AppSettings({
    this.id = 0,
    AppThemeSetting theme = AppThemeSetting.light, // default: Romantic Light
    AppLanguage language = AppLanguage.indonesian,
    this.ttsEnabled = false,
    this.ttsAutoPlay = false,
    this.ttsBackend = 'gemma',
    this.sttBackend = 'gemma',
    this.ttsModel = 'inflect',
    this.sttModel = 'moonshine',
    this.notificationMorningEnabled = false,
    this.notificationMorningTime = '08:00',
    this.notificationCheckinEnabled = false,
    this.modelVariant = 'qwen2.5-1.5b',
    this.modelSource = '',
    this.modelUrl = '',
    this.isAgeVerified = false,
    this.isOnboardingDone = false,
    this.isPersonaSetup = false,
    this.conversationSummary = '',
  }) {
    themeIndex = theme.index;
    languageIndex = language.index;
  }

  /// Returns a new [AppSettings] instance with selected fields overridden.
  /// Preserves the ObjectBox [id] so [put()] updates the existing record.
  AppSettings copyWith({
    AppThemeSetting? theme,
    AppLanguage? language,
    bool? ttsEnabled,
    bool? ttsAutoPlay,
    String? ttsBackend,
    String? sttBackend,
    String? ttsModel,
    String? sttModel,
    bool? notificationMorningEnabled,
    String? notificationMorningTime,
    bool? notificationCheckinEnabled,
    String? modelVariant,
    String? modelSource,
    String? modelUrl,
    bool? isAgeVerified,
    bool? isOnboardingDone,
    bool? isPersonaSetup,
    String? conversationSummary,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsAutoPlay: ttsAutoPlay ?? this.ttsAutoPlay,
      ttsBackend: ttsBackend ?? this.ttsBackend,
      sttBackend: sttBackend ?? this.sttBackend,
      ttsModel: ttsModel ?? this.ttsModel,
      sttModel: sttModel ?? this.sttModel,
      notificationMorningEnabled: notificationMorningEnabled ?? this.notificationMorningEnabled,
      notificationMorningTime: notificationMorningTime ?? this.notificationMorningTime,
      notificationCheckinEnabled: notificationCheckinEnabled ?? this.notificationCheckinEnabled,
      modelVariant: modelVariant ?? this.modelVariant,
      modelSource: modelSource ?? this.modelSource,
      modelUrl: modelUrl ?? this.modelUrl,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      isOnboardingDone: isOnboardingDone ?? this.isOnboardingDone,
      isPersonaSetup: isPersonaSetup ?? this.isPersonaSetup,
      conversationSummary: conversationSummary ?? this.conversationSummary,
    )..id = id;
  }
}

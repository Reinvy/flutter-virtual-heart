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
  String ttsBackend = 'system'; // 'gemma' (on-device) | 'system'
  String sttBackend = 'system'; // 'gemma' (on-device) | 'system'
  String ttsModel = 'inflect'; // 'inflect' | 'matcha' | 'qwen3'
  String sttModel = 'moonshine';
  bool notificationMorningEnabled = false;
  String notificationMorningTime = '08:00';
  bool notificationCheckinEnabled = false;

  /// Jarak waktu (jam) sebelum notifikasi check-in muncul.
  int notificationCheckinHours = 6;

  /// Identitas model LLM aktif = **nama file** yang dipakai
  /// `FlutterEdgeAi.isModelInstalled`. String kosong = belum dipilih.
  String modelVariant = '';
  String modelSource = ''; // '' | 'network' | 'file'
  String modelUrl = '';
  bool isAgeVerified = false;
  bool isOnboardingDone = false;
  bool isPersonaSetup = false;
  String conversationSummary = '';

  /// Jumlah pesan (tidak difilter) saat ringkasan terakhir dibuat (FR-13).
  int summaryMessageCount = 0;

  // Enum backing fields (stored as int index)
  int themeIndex = 0;
  int languageIndex = 0;

  // Getter meng-clamp index: baris rusak tidak boleh melempar RangeError.
  AppThemeSetting get theme => _enumAt(AppThemeSetting.values, themeIndex);
  set theme(AppThemeSetting value) => themeIndex = value.index;

  AppLanguage get language => _enumAt(AppLanguage.values, languageIndex);
  set language(AppLanguage value) => languageIndex = value.index;

  /// Pilihan interval check-in yang didukung UI.
  static const List<int> checkinHourOptions = [1, 3, 6, 12];

  static const Set<String> _voiceBackends = {'gemma', 'system'};
  static const Set<String> _ttsModels = {'inflect', 'matcha', 'qwen3'};
  static const Set<String> _modelSources = {'', 'network', 'file'};
  static final RegExp _hhmm = RegExp(r'^\d{2}:\d{2}$');

  AppSettings({
    this.id = 0,
    AppThemeSetting theme = AppThemeSetting.light, // default: Romantic Light
    AppLanguage language = AppLanguage.indonesian,
    this.ttsEnabled = false,
    this.ttsAutoPlay = false,
    this.ttsBackend = 'system',
    this.sttBackend = 'system',
    this.ttsModel = 'inflect',
    this.sttModel = 'moonshine',
    this.notificationMorningEnabled = false,
    this.notificationMorningTime = '08:00',
    this.notificationCheckinEnabled = false,
    this.notificationCheckinHours = 6,
    this.modelVariant = '',
    this.modelSource = '',
    this.modelUrl = '',
    this.isAgeVerified = false,
    this.isOnboardingDone = false,
    this.isPersonaSetup = false,
    this.conversationSummary = '',
    this.summaryMessageCount = 0,
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
    int? notificationCheckinHours,
    String? modelVariant,
    String? modelSource,
    String? modelUrl,
    bool? isAgeVerified,
    bool? isOnboardingDone,
    bool? isPersonaSetup,
    String? conversationSummary,
    int? summaryMessageCount,
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
      notificationCheckinHours: notificationCheckinHours ?? this.notificationCheckinHours,
      modelVariant: modelVariant ?? this.modelVariant,
      modelSource: modelSource ?? this.modelSource,
      modelUrl: modelUrl ?? this.modelUrl,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      isOnboardingDone: isOnboardingDone ?? this.isOnboardingDone,
      isPersonaSetup: isPersonaSetup ?? this.isPersonaSetup,
      conversationSummary: conversationSummary ?? this.conversationSummary,
      summaryMessageCount: summaryMessageCount ?? this.summaryMessageCount,
    )..id = id;
  }

  /// Menyalin baris yang mungkin rusak (dibaca dari versi aplikasi lama atau
  /// data korup) menjadi nilai yang dijamin valid.
  ///
  /// Dipanggil sekali per boot oleh `ObjectBoxService.getOrCreateSettings`.
  AppSettings normalized() {
    return copyWith(
      ttsBackend: _voiceBackends.contains(ttsBackend) ? ttsBackend : 'system',
      sttBackend: _voiceBackends.contains(sttBackend) ? sttBackend : 'system',
      ttsModel: _ttsModels.contains(ttsModel) ? ttsModel : 'inflect',
      sttModel: 'moonshine',
      modelSource: _modelSources.contains(modelSource) ? modelSource : '',
      notificationMorningTime: isValidMorningTime(notificationMorningTime)
          ? notificationMorningTime
          : '08:00',
      notificationCheckinHours: checkinHourOptions.contains(notificationCheckinHours)
          ? notificationCheckinHours
          : 6,
      theme: _enumAt(AppThemeSetting.values, themeIndex),
      language: _enumAt(AppLanguage.values, languageIndex),
    );
  }

  /// `HH:mm` dengan jam 0–23 dan menit 0–59.
  static bool isValidMorningTime(String value) {
    if (!_hhmm.hasMatch(value)) return false;
    final hour = int.tryParse(value.substring(0, 2));
    final minute = int.tryParse(value.substring(3, 5));
    if (hour == null || minute == null) return false;
    return hour <= 23 && minute <= 59;
  }

  static T _enumAt<T>(List<T> values, int index) {
    final safe = index < 0 ? 0 : (index >= values.length ? values.length - 1 : index);
    return values[safe];
  }
}

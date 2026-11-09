// Unit test — AppStrings (ID + EN) & DateFormatter.
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/core/utils/date_formatter.dart';

/// Kunci yang ditambahkan pada remediasi audit: wajib ada di kedua bahasa.
List<(String, String Function(AppStrings))> _newKeys() => [
  ('safetyExplicit', (s) => s.safetyExplicit),
  ('safetyExplicitOutput', (s) => s.safetyExplicitOutput),
  ('safetySelfHarm', (s) => s.safetySelfHarm),
  ('safetyProfessionalAdvice', (s) => s.safetyProfessionalAdvice),
  ('safetyHateSpeech', (s) => s.safetyHateSpeech),
  ('safetyViolence', (s) => s.safetyViolence),
  ('safetyPersonaBreak', (s) => s.safetyPersonaBreak),
  ('chatStop', (s) => s.chatStop),
  ('chatGenerationFailed', (s) => s.chatGenerationFailed),
  ('chatContextLimit', (s) => s.chatContextLimit),
  ('chatModelUnavailable', (s) => s.chatModelUnavailable),
  ('chatInterrupted', (s) => s.chatInterrupted),
  ('chatRetry', (s) => s.chatRetry),
  ('chatDismiss', (s) => s.chatDismiss),
  ('chatSpeak', (s) => s.chatSpeak),
  ('chatStopSpeaking', (s) => s.chatStopSpeaking),
  ('chatOpenProfile', (s) => s.chatOpenProfile),
  ('chatSend', (s) => s.chatSend),
  ('chatMicStart', (s) => s.chatMicStart),
  ('chatMicStop', (s) => s.chatMicStop),
  ('chatMicPermission', (s) => s.chatMicPermission),
  ('chatMicOpenSettings', (s) => s.chatMicOpenSettings),
  ('chatTtsDisabled', (s) => s.chatTtsDisabled),
  ('modelCurrent', (s) => s.modelCurrent),
  ('modelChange', (s) => s.modelChange),
  ('modelActive', (s) => s.modelActive),
  ('modelUse', (s) => s.modelUse),
  ('modelNotInstalled', (s) => s.modelNotInstalled),
  ('modelErrorNetwork', (s) => s.modelErrorNetwork),
  ('modelErrorAuth', (s) => s.modelErrorAuth),
  ('modelErrorNotFound', (s) => s.modelErrorNotFound),
  ('modelErrorRateLimit', (s) => s.modelErrorRateLimit),
  ('modelErrorStorage', (s) => s.modelErrorStorage),
  ('modelErrorInvalidFile', (s) => s.modelErrorInvalidFile),
  ('modelErrorEngine', (s) => s.modelErrorEngine),
  ('modelErrorUnknown', (s) => s.modelErrorUnknown),
  ('modelFileEmpty', (s) => s.modelFileEmpty),
  ('modelCancelledSnack', (s) => s.modelCancelledSnack),
  ('modelTypeTitle', (s) => s.modelTypeTitle),
  ('settingsModel', (s) => s.settingsModel),
  ('settingsCheckinDesc', (s) => s.settingsCheckinDesc),
  ('settingsCheckinHours', (s) => s.settingsCheckinHours),
  ('settingsCheckinHoursValue', (s) => s.settingsCheckinHoursValue(3)),
  ('settingsDiscardTitle', (s) => s.settingsDiscardTitle),
  ('settingsDiscardBody', (s) => s.settingsDiscardBody),
  ('settingsDiscard', (s) => s.settingsDiscard),
  ('settingsMicPermissionNotRequested', (s) => s.settingsMicPermissionNotRequested),
  ('settingsMicPermissionRequest', (s) => s.settingsMicPermissionRequest),
  ('settingsNotifPermissionUndetermined', (s) => s.settingsNotifPermissionUndetermined),
  ('settingsNotifPermissionEnable', (s) => s.settingsNotifPermissionEnable),
  ('settingsNotifPermissionDeniedSnack', (s) => s.settingsNotifPermissionDeniedSnack),
  ('settingsPrivacyPolicy', (s) => s.settingsPrivacyPolicy),
  ('settingsVoiceBackendOnDevice', (s) => s.settingsVoiceBackendOnDevice),
  ('privacyTitle', (s) => s.privacyTitle),
  ('privacyPolicy', (s) => s.privacyPolicy),
  ('ageGatePrivacyLink', (s) => s.ageGatePrivacyLink),
  ('commonClose', (s) => s.commonClose),
  ('settingsExportTitle', (s) => s.settingsExportTitle),
  ('settingsExportDate', (s) => s.settingsExportDate('01/01/2026 10:00')),
  ('settingsExportPersona', (s) => s.settingsExportPersona('Luna')),
  ('settingsExportUserFallback', (s) => s.settingsExportUserFallback),
  ('settingsExportAiFallback', (s) => s.settingsExportAiFallback),
  ('settingsExportSaved', (s) => s.settingsExportSaved),
  ('settingsExportCancelled', (s) => s.settingsExportCancelled),
];

void main() {
  const id = IndonesianStrings();
  const en = EnglishStrings();

  group('AppStrings', () {
    test('kunci inti tidak kosong (ID & EN)', () {
      final core = <String Function(AppStrings)>[
        (s) => s.appName,
        (s) => s.ageGateTitle,
        (s) => s.ageGateConfirm,
        (s) => s.onboardingPage2Body,
        (s) => s.personaCreateTitle,
        (s) => s.personaSave,
        (s) => s.modelLoadingTitle,
        (s) => s.modelRetry,
        (s) => s.chatInputHint,
        (s) => s.moodHappy,
        (s) => s.memoryTitle,
        (s) => s.settingsTitle,
        (s) => s.settingsThemeLight,
        (s) => s.timeJustNow,
      ];
      for (final get in core) {
        expect(get(id).trim(), isNotEmpty);
        expect(get(en).trim(), isNotEmpty);
      }
    });

    test('semua kunci baru terisi di kedua bahasa', () {
      for (final (name, read) in _newKeys()) {
        expect(read(id).trim(), isNotEmpty, reason: 'ID kosong: $name');
        expect(read(en).trim(), isNotEmpty, reason: 'EN kosong: $name');
      }
    });

    test('copy kebijakan privasi menyebut batas jaringan dan penghapusan data', () {
      expect(id.privacyPolicy, contains('Jaringan hanya dipakai'));
      expect(id.privacyPolicy, contains('Data & Privasi'));
      expect(en.privacyPolicy, contains('Network access is used only'));
      expect(en.privacyPolicy, contains('Data & Privacy'));
    });

    test('age gate hanya mengklaim persetujuan kebijakan privasi', () {
      expect(id.ageGateTerms, isNot(contains('Syarat')));
      expect(en.ageGateTerms, isNot(contains('Terms')));
      expect(id.ageGateTerms, contains('Kebijakan Privasi'));
    });

    test('daftar pesan notifikasi terisi di kedua bahasa', () {
      expect(id.morningMessages, isNotEmpty);
      expect(en.morningMessages, hasLength(id.morningMessages.length));
      expect(id.checkinMessages, isNotEmpty);
      expect(en.checkinMessages, hasLength(id.checkinMessages.length));
    });

    test('placeholder terisi', () {
      expect(
        fillPlaceholders(id.chatEmptyGreeting, {'name': 'Babe'}),
        'Hai, Babe!',
      );
    });
  });

  group('DateFormatter', () {
    test('formatRelative default Bahasa Indonesia', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now.subtract(const Duration(seconds: 30))), 'Baru saja');
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(minutes: 5))),
        '5 menit lalu',
      );
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(hours: 3))),
        '3 jam lalu',
      );
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(days: 2))),
        '2 hari lalu',
      );
    });

    test('formatRelative bahasa Inggris memakai bentuk tunggal yang benar', () {
      const en = EnglishStrings();
      final now = DateTime.now();
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(minutes: 1)), en),
        '1 minute ago',
      );
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(hours: 1)), en),
        '1 hour ago',
      );
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(days: 1)), en),
        '1 day ago',
      );
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(days: 2)), en),
        '2 days ago',
      );
    });

    test('formatTime & formatDate', () {
      final dt = DateTime(2026, 8, 25, 9, 5);
      expect(DateFormatter.formatTime(dt), '09:05');
      // formatDate memakai locale sistem (default en_US di environment test).
      expect(DateFormatter.formatDate(dt), isNotEmpty);
    });
  });
}

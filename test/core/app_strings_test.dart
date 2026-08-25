// Unit test — AppStrings (ID + EN) & DateFormatter
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/core/utils/date_formatter.dart';

void main() {
  group('AppStrings', () {
    final id = const IndonesianStrings();
    final en = const EnglishStrings();

    test('semua kunci string non-null dan non-kosong (ID)', () {
      final fields = <String>[
        id.appName,
        id.ageGateTitle, id.ageGateConfirm, id.ageGateDecline,
        id.onboardingPage1Title, id.onboardingGetStarted,
        id.personaCreateTitle, id.personaNameHint, id.personaSave,
        id.modelLoadingTitle, id.modelRetry,
        id.chatInputHint, id.moodHappy,
        id.memoryTitle, id.memoryResetAllTitle,
        id.settingsTitle, id.settingsThemeLight,
        id.timeJustNow,
      ];
      for (final f in fields) {
        expect(f, isNotNull, reason: 'kunci ID null');
        expect(f.trim(), isNotEmpty, reason: 'kunci ID kosong: "$f"');
      }
    });

    test('semua kunci string non-null dan non-kosong (EN)', () {
      final fields = <String>[
        en.appName,
        en.ageGateTitle, en.ageGateConfirm, en.ageGateDecline,
        en.onboardingPage1Title, en.onboardingGetStarted,
        en.personaCreateTitle, en.personaNameHint, en.personaSave,
        en.modelLoadingTitle, en.modelRetry,
        en.chatInputHint, en.moodHappy,
        en.memoryTitle, en.memoryResetAllTitle,
        en.settingsTitle, en.settingsThemeLight,
        en.timeJustNow,
      ];
      for (final f in fields) {
        expect(f, isNotNull, reason: 'kunci EN null');
        expect(f.trim(), isNotEmpty, reason: 'kunci EN kosong: "$f"');
      }
    });

    test('format waktu relatif berbeda per bahasa', () {
      expect(id.timeMinutesAgo(5), '5 menit lalu');
      expect(en.timeMinutesAgo(5), '5 minutes ago');
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

    test('formatRelative bahasa Inggris', () {
      const en = EnglishStrings();
      final now = DateTime.now();
      expect(
        DateFormatter.formatRelative(now.subtract(const Duration(hours: 1)), en),
        '1 hours ago',
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

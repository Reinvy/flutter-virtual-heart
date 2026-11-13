// Unit test — guard route router (resolveRedirect).
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/router/app_router.dart';
import 'package:virtual_heart/models/app_settings.dart';

AppSettings _settings({
  bool age = false,
  bool onboarding = false,
  bool persona = false,
}) {
  return AppSettings(
    isAgeVerified: age,
    isOnboardingDone: onboarding,
    isPersonaSetup: persona,
  );
}

String? _resolve(String path, {AppSettings? settings, bool modelReady = false}) =>
    resolveRedirect(
      path: path,
      settings: settings ?? _settings(),
      isModelReady: modelReady,
    );

void main() {
  group('resolveRedirect — urutan gate', () {
    test('splash selalu lolos', () {
      expect(_resolve(AppRoutes.splash), isNull);
      expect(_resolve(AppRoutes.splash, settings: _settings(age: true)), isNull);
    });

    test('/privacy lolos sebelum gate apa pun', () {
      expect(_resolve(AppRoutes.privacy), isNull);
      expect(_resolve(AppRoutes.privacy, settings: _settings(age: true)), isNull);
      expect(
        _resolve(
          AppRoutes.privacy,
          settings: _settings(age: true, onboarding: true, persona: true),
        ),
        isNull,
      );
    });

    test('/model-download tetap boleh dibuka saat model sudah siap', () {
      final settings = _settings(age: true, onboarding: true, persona: true);
      expect(_resolve(AppRoutes.modelDownload, settings: settings, modelReady: true), isNull);
    });

    test('usia belum diverifikasi → age gate', () {
      expect(_resolve(AppRoutes.hub), AppRoutes.ageGate);
      expect(_resolve(AppRoutes.chat), AppRoutes.ageGate);
      expect(_resolve(AppRoutes.memory), AppRoutes.ageGate);
      expect(_resolve(AppRoutes.ageGate), isNull);
    });

    test('onboarding belum selesai → onboarding', () {
      final settings = _settings(age: true);
      expect(_resolve(AppRoutes.chat, settings: settings), AppRoutes.onboarding);
      expect(_resolve(AppRoutes.onboarding, settings: settings), isNull);
    });

    test('persona belum dibuat → persona setup', () {
      final settings = _settings(age: true, onboarding: true);
      expect(_resolve(AppRoutes.chat, settings: settings), AppRoutes.personaSetup);
      expect(_resolve(AppRoutes.personaSetup, settings: settings), isNull);
    });

    test('model belum siap → model download', () {
      final settings = _settings(age: true, onboarding: true, persona: true);
      expect(_resolve(AppRoutes.hub, settings: settings), AppRoutes.modelDownload);
      expect(_resolve(AppRoutes.chat, settings: settings), AppRoutes.modelDownload);
      expect(_resolve(AppRoutes.memory, settings: settings), AppRoutes.modelDownload);
      expect(_resolve(AppRoutes.settings, settings: settings), AppRoutes.modelDownload);
      expect(_resolve(AppRoutes.modelDownload, settings: settings), isNull);
    });

    test('/model-download tanpa verifikasi usia tetap diarahkan ke age gate', () {
      expect(_resolve(AppRoutes.modelDownload), AppRoutes.ageGate);
      expect(
        _resolve(AppRoutes.modelDownload, settings: _settings(age: true)),
        AppRoutes.onboarding,
      );
    });

    test('semua gate lolos → layar setup diarahkan ke hub', () {
      final settings = _settings(age: true, onboarding: true, persona: true);
      expect(_resolve(AppRoutes.ageGate, settings: settings, modelReady: true), AppRoutes.hub);
      expect(
        _resolve(AppRoutes.onboarding, settings: settings, modelReady: true),
        AppRoutes.hub,
      );
      expect(
        _resolve(AppRoutes.personaSetup, settings: settings, modelReady: true),
        AppRoutes.hub,
      );
      expect(_resolve(AppRoutes.hub, settings: settings, modelReady: true), isNull);
      expect(_resolve(AppRoutes.chat, settings: settings, modelReady: true), isNull);
      expect(_resolve(AppRoutes.memory, settings: settings, modelReady: true), isNull);
      expect(_resolve(AppRoutes.settings, settings: settings, modelReady: true), isNull);
    });
  });
}

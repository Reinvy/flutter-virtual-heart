// Penyimpanan API key BYOK terenkripsi (FlutterSecureStorage) + fake in-memory untuk test.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/app_logger.dart';

/// Konstanta prefix & kunci penyimpanan secret BYOK.
abstract final class SecretKeys {
  static const String prefix = 'vh_';
  static const String llmPrefix = 'vh_llm_key_';
  static const String speechPrefix = 'vh_speech_key_';

  static String forLlmProfile(String profileKey) => '$llmPrefix$profileKey';

  static const String elevenLabs = '${speechPrefix}elevenlabs';
  static const String openaiTts = '${speechPrefix}openai_tts';
  static const String openaiStt = '${speechPrefix}openai_stt';
  static const String googleSpeech = '${speechPrefix}google';
}

/// Kontrak penyimpanan rahasia (API key) yang bisa diganti saat pengujian.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAllByokSecrets();

  Future<bool> hasValue(String key) async {
    final value = await read(key);
    return value != null && value.trim().isNotEmpty;
  }
}

/// Implementasi produksi memakai `FlutterSecureStorage`.
///
/// - Android: `AndroidOptions(migrateOnAlgorithmChange: true)` memakai
///   AES-GCM + Android KeyStore modern (v11).
/// - macOS: `MacOsOptions(usesDataProtectionKeychain: false)` agar tetap
///   bekerja pada build lokal tanpa provisioning profile Keychain Sharing.
class SecureSecretStore extends SecretStore {
  SecureSecretStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(migrateOnAlgorithmChange: true),
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    } catch (e) {
      AppLogger.warn('Secure storage read failed for key=$key', e);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await delete(key);
      return;
    }
    await _storage.write(key: key, value: trimmed);
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.debug('Secure storage delete ignored for key=$key', e);
    }
  }

  @override
  Future<void> deleteAllByokSecrets() async {
    try {
      final all = await _storage.readAll();
      for (final key in all.keys) {
        if (key.startsWith(SecretKeys.llmPrefix) ||
            key.startsWith(SecretKeys.speechPrefix)) {
          await delete(key);
        }
      }
    } catch (e) {
      AppLogger.warn('Secure storage BYOK wipe failed', e);
    }
  }
}

/// Implementasi in-memory murni untuk unit/widget test.
class InMemorySecretStore extends SecretStore {
  InMemorySecretStore([Map<String, String>? initial])
    : _data = Map<String, String>.from(initial ?? const {});

  final Map<String, String> _data;

  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_data);

  @override
  Future<String?> read(String key) async {
    final value = _data[key];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  @override
  Future<void> write(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _data.remove(key);
    } else {
      _data[key] = trimmed;
    }
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAllByokSecrets() async {
    _data.removeWhere(
      (key, _) =>
          key.startsWith(SecretKeys.llmPrefix) ||
          key.startsWith(SecretKeys.speechPrefix),
    );
  }
}

final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());

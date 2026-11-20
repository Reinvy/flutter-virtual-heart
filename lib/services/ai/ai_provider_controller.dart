// Controller Riverpod (manual) untuk profil Cloud BYOK & konfigurasi Cloud Speech.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_provider_profile.dart';
import '../../models/app_settings.dart';
import '../../models/cloud_speech_config.dart';
import '../database/objectbox_provider.dart';
import '../settings/settings_service.dart';
import 'secret_store.dart';

/// Mengelola daftar [AiProviderProfile] di ObjectBox + API key terenkripsi di [SecretStore].
class AiProviderProfilesNotifier extends Notifier<List<AiProviderProfile>> {
  @override
  List<AiProviderProfile> build() {
    final db = ref.read(objectBoxServiceProvider);
    final rows = db.aiProviderProfileBox.getAll()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return rows.map((p) => p.normalized()).toList();
  }

  /// Membuat kunci unik stabil untuk profil baru.
  String generateProfileKey(String presetId) {
    final cleanPreset = presetId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    final base = cleanPreset.isEmpty ? 'custom' : cleanPreset;
    return '${base}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Menyimpan (insert/update) [profile] dan opsional memperbarui API key di [SecretStore].
  ///
  /// Bila [apiKey] `null`, API key lama yang tersimpan tidak disentuh.
  /// Bila [apiKey] string kosong, API key yang tersimpan dihapus.
  Future<AiProviderProfile> saveProfile(
    AiProviderProfile profile, {
    String? apiKey,
  }) async {
    final db = ref.read(objectBoxServiceProvider);
    final secrets = ref.read(secretStoreProvider);

    var clean = profile.normalized();
    if (clean.profileKey.isEmpty) {
      clean = clean.copyWith(profileKey: generateProfileKey(clean.presetId));
    }
    if (clean.name.isEmpty) {
      clean = clean.copyWith(
        name: clean.modelId.isNotEmpty ? clean.modelId : clean.providerType.name,
      );
    }

    final savedId = db.aiProviderProfileBox.put(clean);
    clean.id = savedId;

    if (apiKey != null) {
      final secretKey = SecretKeys.forLlmProfile(clean.profileKey);
      if (apiKey.trim().isEmpty) {
        await secrets.delete(secretKey);
      } else {
        await secrets.write(secretKey, apiKey.trim());
      }
    }

    if (ref.mounted) {
      final updated = db.aiProviderProfileBox.getAll()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = updated.map((p) => p.normalized()).toList();
    }
    return clean;
  }

  /// Menghapus profil [profileId] beserta API key-nya.
  ///
  /// Jika profil yang dihapus sedang aktif, `activeCloudProfileId` disetel ke 0
  /// (dan jika sedang mode cloud, kembali ke mode lokal).
  Future<void> deleteProfile(int profileId) async {
    final db = ref.read(objectBoxServiceProvider);
    final secrets = ref.read(secretStoreProvider);

    AiProviderProfile? target;
    for (final p in state) {
      if (p.id == profileId) {
        target = p;
        break;
      }
    }
    if (target != null && target.profileKey.isNotEmpty) {
      await secrets.delete(SecretKeys.forLlmProfile(target.profileKey));
    }
    db.aiProviderProfileBox.remove(profileId);

    final settings = ref.read(appSettingsProvider);
    if (settings.activeCloudProfileId == profileId) {
      ref.read(appSettingsProvider.notifier).save(
        settings.copyWith(
          activeCloudProfileId: 0,
          aiMode: settings.aiMode == AiMode.cloud ? AiMode.local : settings.aiMode,
        ),
      );
    }

    if (ref.mounted) {
      final updated = db.aiProviderProfileBox.getAll()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = updated.map((p) => p.normalized()).toList();
    }
  }

  /// Membaca API key profil dari [SecretStore].
  Future<String> readApiKey(AiProviderProfile profile) async {
    if (profile.profileKey.isEmpty) return '';
    final key = await ref
        .read(secretStoreProvider)
        .read(SecretKeys.forLlmProfile(profile.profileKey));
    return key ?? '';
  }

  /// Mengecek apakah profil sudah memiliki API key (atau host lokal yang boleh tanpa key).
  Future<bool> hasUsableCredentials(AiProviderProfile profile) async {
    if (profile.providerType == LlmProviderType.openai &&
        profile.isLocalNetworkBaseUrl) {
      return true;
    }
    final key = await readApiKey(profile);
    return key.isNotEmpty;
  }
}

final aiProviderProfilesProvider =
    NotifierProvider<AiProviderProfilesNotifier, List<AiProviderProfile>>(
      AiProviderProfilesNotifier.new,
    );

/// Profil Cloud LLM aktif sesuai `AppSettings.activeCloudProfileId`, atau `null`.
final activeCloudProfileProvider = Provider<AiProviderProfile?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  if (settings.activeCloudProfileId <= 0) return null;
  final profiles = ref.watch(aiProviderProfilesProvider);
  for (final p in profiles) {
    if (p.id == settings.activeCloudProfileId) return p;
  }
  return null;
});

/// Mengelola [CloudSpeechConfig] single-row di ObjectBox + resolusi API key speech.
class CloudSpeechConfigNotifier extends Notifier<CloudSpeechConfig> {
  @override
  CloudSpeechConfig build() {
    final db = ref.read(objectBoxServiceProvider);
    return db.getOrCreateCloudSpeechConfig();
  }

  void save(CloudSpeechConfig updated) {
    final clean = updated.normalized();
    ref.read(objectBoxServiceProvider).cloudSpeechConfigBox.put(clean);
    state = clean;
  }

  @override
  bool updateShouldNotify(CloudSpeechConfig previous, CloudSpeechConfig next) =>
      previous.id != next.id || !previous.hasSameValues(next);

  Future<void> saveSpeechApiKey(String secretKey, String value) async {
    final secrets = ref.read(secretStoreProvider);
    if (value.trim().isEmpty) {
      await secrets.delete(secretKey);
    } else {
      await secrets.write(secretKey, value.trim());
    }
  }

  Future<String> readSpeechApiKey(String secretKey) async {
    return (await ref.read(secretStoreProvider).read(secretKey)) ?? '';
  }

  /// Menyelesaikan API key efektif untuk Cloud TTS [backend] (`elevenlabs` / `openai` / `google`).
  ///
  /// Untuk `openai` dan `google`, bila toggle `reuseLlmKey` aktif dan key
  /// khusus kosong, otomatis memakai API key dari profil LLM aktif (atau profil
  /// tersimpan pertama bertipe sama).
  Future<String> resolveTtsApiKey(String backend) async {
    final secrets = ref.read(secretStoreProvider);
    switch (backend) {
      case 'elevenlabs':
        return (await secrets.read(SecretKeys.elevenLabs)) ?? '';
      case 'openai':
        if (state.openaiTtsReuseLlmKey) {
          final reused = await _findLlmKeyForType(LlmProviderType.openai);
          if (reused.isNotEmpty) return reused;
        }
        return (await secrets.read(SecretKeys.openaiTts)) ?? '';
      case 'google':
        if (state.googleSpeechReuseLlmKey) {
          final reused = await _findLlmKeyForType(LlmProviderType.google);
          if (reused.isNotEmpty) return reused;
        }
        return (await secrets.read(SecretKeys.googleSpeech)) ?? '';
      default:
        return '';
    }
  }

  /// Menyelesaikan API key efektif untuk Cloud STT [backend] (`elevenlabs` / `openai` / `google`).
  Future<String> resolveSttApiKey(String backend) async {
    final secrets = ref.read(secretStoreProvider);
    switch (backend) {
      case 'elevenlabs':
        return (await secrets.read(SecretKeys.elevenLabs)) ?? '';
      case 'openai':
        if (state.openaiSttReuseLlmKey) {
          final reused = await _findLlmKeyForType(LlmProviderType.openai);
          if (reused.isNotEmpty) return reused;
        }
        return (await secrets.read(SecretKeys.openaiStt)) ?? '';
      case 'google':
        if (state.googleSpeechReuseLlmKey) {
          final reused = await _findLlmKeyForType(LlmProviderType.google);
          if (reused.isNotEmpty) return reused;
        }
        return (await secrets.read(SecretKeys.googleSpeech)) ?? '';
      default:
        return '';
    }
  }

  Future<String> _findLlmKeyForType(LlmProviderType type) async {
    final secrets = ref.read(secretStoreProvider);
    final active = ref.read(activeCloudProfileProvider);
    if (active != null && active.providerType == type) {
      final key = await secrets.read(SecretKeys.forLlmProfile(active.profileKey));
      if (key != null && key.isNotEmpty) return key;
    }
    final profiles = ref.read(aiProviderProfilesProvider);
    for (final p in profiles) {
      if (p.providerType != type) continue;
      final key = await secrets.read(SecretKeys.forLlmProfile(p.profileKey));
      if (key != null && key.isNotEmpty) return key;
    }
    return '';
  }
}

final cloudSpeechConfigProvider =
    NotifierProvider<CloudSpeechConfigNotifier, CloudSpeechConfig>(
      CloudSpeechConfigNotifier.new,
    );

import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/model/model_ready_provider.dart';
import '../../features/settings/settings_controller.dart';
import '../../models/message.dart';
import 'model_catalog.dart';

/// Status model LLM on-device.
class ModelStatus {
  /// Model siap inferensi.
  final bool ready;

  /// Progress download 0..1 (hanya relevan saat download berlangsung).
  final double progress;

  /// Nama model aktif (null bila belum ada).
  final String? modelName;

  /// Pesan error ramah (null bila tidak ada).
  final String? error;

  /// Sedang mengunduh/memasang.
  final bool installing;

  const ModelStatus({
    this.ready = false,
    this.progress = 0,
    this.modelName,
    this.error,
    this.installing = false,
  });

  ModelStatus copyWith({
    bool? ready,
    double? progress,
    String? modelName,
    String? error,
    bool? installing,
  }) {
    return ModelStatus(
      ready: ready ?? this.ready,
      progress: progress ?? this.progress,
      modelName: modelName ?? this.modelName,
      error: error ?? this.error,
      installing: installing ?? this.installing,
    );
  }
}

/// Riverpod notifier yang mengelola siklus hidup model LLM on-device.
///
/// Mendukung tiga sumber:
/// - **Network** (`installFromNetwork`) — download dari HuggingFace + progress.
/// - **File** (`installFromFile`) — model lokal yang dipilih pengguna.
/// - **Terpasang** (`build`) — jika model sudah terinstal, langsung dipakai.
class ModelServiceNotifier extends AsyncNotifier<ModelStatus> {
  /// Soft cap konteks per request.
  static const int maxContextChars = 6000;

  gemma.InferenceModel? _model;
  gemma.CancelToken? _cancelToken;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  Future<ModelStatus> build() async {
    final settings = ref.read(appSettingsProvider);

    // Model sudah pernah dipilih & terinstal → langsung aktifkan.
    if (settings.modelVariant.isNotEmpty) {
      try {
        final installed = await gemma.FlutterGemma.isModelInstalled(
          settings.modelVariant,
        );
        if (installed) {
          _model = await gemma.FlutterGemma.getActiveModel(
            preferredBackend: gemma.PreferredBackend.cpu,
            maxTokens: 2048,
          );
          ref.read(modelReadyProvider.notifier).setReady();
          return ModelStatus(
            ready: true,
            modelName: settings.modelVariant,
          );
        }
      } catch (_) {
        // Model rusak → lanjut ke install ulang.
      }
    }

    // Model default (Qwen 2.5 1.5B .litertlm) bila belum ada pilihan.
    if (settings.modelSource.isEmpty) {
      try {
        await _installWithProgress(kDefaultModelOption, hfToken: null);
        return state.value ?? const ModelStatus(ready: true);
      } catch (e) {
        return ModelStatus(error: _friendlyError(e));
      }
    }

    return const ModelStatus();
  }

  // -------------------------------------------------------------------------
  // Install dari network / file
  // -------------------------------------------------------------------------

  /// Mengunduh [option] dari HuggingFace dengan progress.
  Future<void> installFromNetwork(ModelOption option, {String? hfToken}) async {
    state = const AsyncLoading();
    _cancelToken = gemma.CancelToken();
    try {
      await _installWithProgress(option, hfToken: hfToken);
    } catch (e) {
      state = AsyncError(_friendlyError(e), StackTrace.current);
    }
  }

  /// Memasang model dari file lokal (upload pengguna).
  Future<void> installFromFile(String path, ModelOption option) async {
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        await gemma.FlutterGemma.installModel(
          modelType: option.gemmaModelType,
          fileType: option.gemmaFileType,
        ).fromFile(path).install();

        _model = await gemma.FlutterGemma.getActiveModel(
          preferredBackend: gemma.PreferredBackend.cpu,
          maxTokens: 2048,
        );

        await _persistSelection(option);
        ref.read(modelReadyProvider.notifier).setReady();
        return ModelStatus(ready: true, modelName: option.fileName);
      });
    } catch (e) {
      state = AsyncError(_friendlyError(e), StackTrace.current);
    }
  }

  /// Membatalkan download yang sedang berjalan.
  Future<void> cancelDownload() async {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('User cancelled download');
    }
  }

  // -------------------------------------------------------------------------
  // Private
  // -------------------------------------------------------------------------

  Future<void> _installWithProgress(ModelOption option, {String? hfToken}) async {
    await gemma.FlutterGemma.installModel(
      modelType: option.gemmaModelType,
      fileType: option.gemmaFileType,
    )
        .fromNetwork(option.url, token: hfToken)
        .withCancelToken(_cancelToken!)
        .withProgress((progress) {
          state = AsyncData(
            (state.value ?? const ModelStatus()).copyWith(
              progress: progress / 100,
              installing: true,
              modelName: option.name,
            ),
          );
        })
        .install();

    _model = await gemma.FlutterGemma.getActiveModel(
      preferredBackend: gemma.PreferredBackend.cpu,
      maxTokens: 2048,
    );

    await _persistSelection(option);
    ref.read(modelReadyProvider.notifier).setReady();
    state = AsyncData(ModelStatus(ready: true, modelName: option.fileName));
  }

  Future<void> _persistSelection(ModelOption option) async {
    final settings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).save(
      settings.copyWith(
        modelVariant: option.fileName,
        modelSource: 'network',
        modelUrl: option.url,
      ),
    );
  }

  /// Membaca token HuggingFace dari SharedPreferences (tidak pernah di-log).
  Future<String?> readHfToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('hf_token');
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<void> saveHfToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hf_token', token.trim());
  }

  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains('404')) return 'Model tidak ditemukan di server.';
    if (msg.contains('401') || msg.contains('403')) {
      return 'Akses ditolak — periksa token HuggingFace untuk model gated.';
    }
    if (msg.contains('429')) return 'Terlalu banyak permintaan. Coba lagi nanti.';
    if (msg.contains('cancel')) return 'Unduhan dibatalkan.';
    return 'Gagal memasang model. Coba lagi.';
  }

  // -------------------------------------------------------------------------
  // Inference
  // -------------------------------------------------------------------------

  /// Streaming token untuk [fullPrompt].
  Stream<String> generateResponseStream(
    String fullPrompt, {
    String? systemInstruction,
    List<Message>? history,
  }) async* {
    final model = _model;
    if (model == null) throw StateError('Model not initialized');

    final chat = await model.createChat(temperature: 0.9, randomSeed: 1, topK: 50, topP: 0.95);

    await chat.clearHistory();

    if (systemInstruction != null && history != null) {
      await chat.addQueryChunk(gemma.Message.text(text: systemInstruction, isUser: true));
      for (final message in history) {
        await chat.addQueryChunk(
          gemma.Message.text(text: message.content, isUser: message.role == MessageRole.user),
        );
      }
      await chat.addQueryChunk(gemma.Message.text(text: fullPrompt, isUser: true));

      await for (final chunk in chat.generateChatResponseAsync()) {
        if (chunk is gemma.TextResponse) {
          yield chunk.token;
        }
      }
    } else {
      await chat.addQueryChunk(gemma.Message.text(text: fullPrompt, isUser: true));

      await for (final chunk in chat.generateChatResponseAsync()) {
        if (chunk is gemma.TextResponse) {
          yield chunk.token;
        }
      }
    }
  }

  /// Mengumpulkan semua token streaming menjadi satu string.
  Future<String> generateResponse(
    String fullPrompt, {
    String? systemInstruction,
    List<Message>? history,
  }) async {
    final buffer = StringBuffer();
    await for (final token in generateResponseStream(
      fullPrompt,
      systemInstruction: systemInstruction,
      history: history,
    )) {
      buffer.write(token);
    }
    return buffer.toString();
  }

  // -------------------------------------------------------------------------
  // Reset / recovery
  // -------------------------------------------------------------------------

  /// Membuang model & memaksa re-install.
  Future<void> reset() async {
    _model = null;
    ref.read(modelReadyProvider.notifier).reset();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final settings = ref.read(appSettingsProvider);
      if (settings.modelVariant.isNotEmpty) {
        await gemma.FlutterGemma.uninstallModel(settings.modelVariant);
        await gemma.FlutterGemma.clearActiveInferenceIdentity();
      }
      return const ModelStatus();
    });
  }
}

final modelServiceProvider = AsyncNotifierProvider<ModelServiceNotifier, ModelStatus>(
  ModelServiceNotifier.new,
);

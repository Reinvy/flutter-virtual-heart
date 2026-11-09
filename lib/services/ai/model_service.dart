import 'package:flutter_edge_ai/flutter_edge_ai.dart' as edge_ai;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/model/model_ready_provider.dart';
import '../../features/settings/settings_controller.dart';
import 'model_catalog.dart';

/// Jenis kegagalan pemasangan/pemuatan model.
enum ModelErrorKind {
  network,
  auth,
  notFound,
  rateLimited,
  storage,
  invalidFile,
  engine,
  cancelled,
  unknown,
}

/// Kegagalan model yang membawa [kind] untuk dipetakan ke `AppStrings`.
class ModelException implements Exception {
  final ModelErrorKind kind;
  final Object? cause;
  const ModelException(this.kind, [this.cause]);

  @override
  String toString() => 'ModelException(${kind.name})';
}

/// Prompt melebihi context window model aktif.
///
/// Dilempar oleh [ModelServiceNotifier.generateResponseStream] agar lapisan
/// fitur tidak perlu mengimpor exception engine.
class ContextLimitReachedException implements Exception {
  const ContextLimitReachedException();

  @override
  String toString() => 'ContextLimitReachedException';
}

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
///
/// `AppSettings.modelVariant` menyimpan **nama file** model (identitas yang
/// dipakai `FlutterEdgeAi.isModelInstalled`), `modelSource` menyimpan asal
/// pemasangan (`network`/`file`), dan `modelUrl` menyimpan URL asal.
class ModelServiceNotifier extends AsyncNotifier<ModelStatus> {
  edge_ai.InferenceModel? _model;
  edge_ai.CancelToken? _cancelToken;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  Future<ModelStatus> build() async {
    final settings = ref.read(appSettingsProvider);

    // Model sudah pernah dipilih & terinstal → langsung aktifkan.
    if (settings.modelVariant.isNotEmpty) {
      try {
        final installed = await edge_ai.FlutterEdgeAi.isModelInstalled(
          settings.modelVariant,
        );
        if (installed) {
          _model = await edge_ai.FlutterEdgeAi.getActiveModel(
            preferredBackend: edge_ai.PreferredBackend.cpu,
            maxTokens: 2048,
          );
          ref.read(modelReadyProvider.notifier).setReady();
          return ModelStatus(ready: true, modelName: settings.modelVariant);
        }
      } catch (_) {
        // Model rusak → biarkan pengguna memasang ulang dari layar model.
      }
    }

    // Belum pernah ada pilihan model → pasang model default.
    if (settings.modelSource.isEmpty) {
      _cancelToken = edge_ai.CancelToken();
      try {
        await _installWithProgress(kDefaultModelOption, hfToken: null);
        return state.value ?? const ModelStatus(ready: true);
      } catch (e) {
        return ModelStatus(error: _friendlyError(e));
      } finally {
        _cancelToken = null;
      }
    }

    // Ada pilihan tersimpan tapi file-nya tidak ada: jangan auto-install ulang.
    return const ModelStatus();
  }

  // -------------------------------------------------------------------------
  // Install dari network / file
  // -------------------------------------------------------------------------

  /// Mengunduh [option] dari HuggingFace dengan progress.
  Future<void> installFromNetwork(ModelOption option, {String? hfToken}) async {
    state = const AsyncLoading();
    _cancelToken = edge_ai.CancelToken();
    try {
      await _installWithProgress(option, hfToken: hfToken);
    } catch (e) {
      state = AsyncError(_friendlyError(e), StackTrace.current);
    } finally {
      _cancelToken = null;
    }
  }

  /// Memasang model dari file lokal (upload pengguna).
  Future<void> installFromFile(String path, ModelOption option) async {
    state = const AsyncLoading();
    _cancelToken = null;
    state = await AsyncValue.guard(() async {
      await edge_ai.FlutterEdgeAi.installModel(
        modelType: option.edgeAiModelType,
        fileType: option.edgeAiFileType,
      ).fromFile(path).install();

      _model = await edge_ai.FlutterEdgeAi.getActiveModel(
        preferredBackend: edge_ai.PreferredBackend.cpu,
        maxTokens: 2048,
      );

      await _persistSelection(option, source: 'file', url: '');
      ref.read(modelReadyProvider.notifier).setReady();
      return ModelStatus(ready: true, modelName: option.fileName);
    });
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
    final token = _cancelToken ??= edge_ai.CancelToken();

    await edge_ai.FlutterEdgeAi.installModel(
      modelType: option.edgeAiModelType,
      fileType: option.edgeAiFileType,
    )
        .fromNetwork(option.url, token: hfToken)
        .withCancelToken(token)
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

    _model = await edge_ai.FlutterEdgeAi.getActiveModel(
      preferredBackend: edge_ai.PreferredBackend.cpu,
      maxTokens: 2048,
    );

    await _persistSelection(option, source: 'network', url: option.url);
    ref.read(modelReadyProvider.notifier).setReady();
    state = AsyncData(ModelStatus(ready: true, modelName: option.fileName));
  }

  /// Menyimpan identitas model aktif ke [AppSettings].
  Future<void> _persistSelection(
    ModelOption option, {
    required String source,
    required String url,
  }) async {
    final settings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).save(
      settings.copyWith(
        modelVariant: option.fileName,
        modelSource: source,
        modelUrl: url,
      ),
    );
  }

  /// Menyimpan token HuggingFace (dipakai [main.dart] saat init engine).
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
  Stream<String> generateResponseStream(String fullPrompt) async* {
    final model = _model;
    if (model == null) throw StateError('Model not initialized');

    final chat = await model.openChat(temperature: 0.9, randomSeed: 1, topK: 50, topP: 0.95);
    try {
      await chat.addQueryChunk(edge_ai.Message.text(text: fullPrompt, isUser: true));

      await for (final chunk in chat.generateChatResponseAsync()) {
        if (chunk is edge_ai.TextResponse) {
          yield chunk.token;
        }
      }
    } finally {
      await chat.close();
    }
  }

  /// Mengumpulkan semua token streaming menjadi satu string.
  Future<String> generateResponse(String fullPrompt) async {
    final buffer = StringBuffer();
    await for (final token in generateResponseStream(fullPrompt)) {
      buffer.write(token);
    }
    return buffer.toString();
  }
}

final modelServiceProvider = AsyncNotifierProvider<ModelServiceNotifier, ModelStatus>(
  ModelServiceNotifier.new,
);

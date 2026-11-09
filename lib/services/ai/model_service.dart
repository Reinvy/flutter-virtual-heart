import 'dart:async';
import 'dart:math';

import 'package:flutter_edge_ai/flutter_edge_ai.dart' as edge_ai;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_logger.dart';
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

/// Mengklasifikasikan error engine/IO ke [ModelErrorKind] yang bisa ditampilkan.
///
/// Fungsi murni (tidak menyentuh provider) supaya bisa diuji terpisah.
ModelErrorKind classifyModelError(Object error) {
  if (error is ModelException) return error.kind;
  if (error is ContextLimitReachedException) return ModelErrorKind.engine;

  final message = error.toString().toLowerCase();
  if (message.contains('cancel')) return ModelErrorKind.cancelled;
  if (message.contains('404') || message.contains('not found')) {
    return ModelErrorKind.notFound;
  }
  if (message.contains('401') ||
      message.contains('403') ||
      message.contains('unauthorized') ||
      message.contains('forbidden')) {
    return ModelErrorKind.auth;
  }
  if (message.contains('429') ||
      message.contains('rate limit') ||
      message.contains('too many')) {
    return ModelErrorKind.rateLimited;
  }
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('host lookup') ||
      message.contains('timed out')) {
    return ModelErrorKind.network;
  }
  if (message.contains('space') ||
      message.contains('storage') ||
      message.contains('enospc') ||
      message.contains('disk')) {
    return ModelErrorKind.storage;
  }
  if (message.contains('invalid') ||
      message.contains('corrupt') ||
      message.contains('format')) {
    return ModelErrorKind.invalidFile;
  }
  if (error is StateError) return ModelErrorKind.engine;
  return ModelErrorKind.unknown;
}

/// Status model LLM on-device.
class ModelStatus {
  /// Model siap inferensi.
  final bool ready;

  /// Progress download 0..1 (hanya relevan saat download berlangsung).
  final double progress;

  /// Nama model aktif (null bila belum ada).
  final String? modelName;

  /// Sedang mengunduh/memasang.
  final bool installing;

  const ModelStatus({
    this.ready = false,
    this.progress = 0,
    this.modelName,
    this.installing = false,
  });

  ModelStatus copyWith({
    bool? ready,
    double? progress,
    String? modelName,
    bool? installing,
  }) {
    return ModelStatus(
      ready: ready ?? this.ready,
      progress: progress ?? this.progress,
      modelName: modelName ?? this.modelName,
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

  /// Chat yang sedang aktif — dipakai [stopGeneration].
  edge_ai.InferenceChat? _activeChat;

  /// Selesai saat proses install (sukses/gagal/batal) berakhir.
  Completer<void>? _installDone;

  /// Antrean inferensi: chat, ekstraksi memori, dan ringkasan tidak boleh
  /// berjalan bersamaan pada instance engine yang sama.
  Completer<void>? _lockHeld;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  Future<ModelStatus> build() async {
    ref.onDispose(() {
      _cancelToken?.cancel('provider disposed');
      final chat = _activeChat;
      if (chat != null) unawaited(chat.close());
      final model = _model;
      if (model != null) unawaited(model.close());
    });

    final settings = ref.read(appSettingsProvider);

    // Model sudah pernah dipilih & terinstal → langsung aktifkan.
    if (settings.modelVariant.isNotEmpty) {
      if (!await edge_ai.FlutterEdgeAi.isModelInstalled(settings.modelVariant)) {
        return const ModelStatus();
      }
      return _activate(settings.modelVariant);
    }

    // Belum pernah memilih model. Hanya pakai otomatis bila tepat satu file
    // terpasang (daftar juga memuat model TTS/STT, jadi >1 tidak bisa ditebak).
    try {
      final installed = await edge_ai.FlutterEdgeAi.listInstalledModels();
      if (installed.length != 1) return const ModelStatus();
      final fileName = installed.first;
      try {
        final status = await _activate(fileName);
        await _persistSelection(
          fileName: fileName,
          source: 'file',
          url: '',
        );
        return status;
      } catch (e) {
        // File bisa jadi model suara — jangan blokir startup.
        AppLogger.debug('Auto-activate skipped', e);
        return const ModelStatus();
      }
    } catch (e) {
      AppLogger.debug('Installed model scan skipped', e);
      return const ModelStatus();
    }
  }

  Future<ModelStatus> _activate(String fileName) async {
    try {
      _model = await edge_ai.FlutterEdgeAi.getActiveModel(
        preferredBackend: edge_ai.PreferredBackend.cpu,
        maxTokens: 2048,
      );
    } catch (e) {
      throw ModelException(ModelErrorKind.engine, e);
    }
    ref.read(modelReadyProvider.notifier).setReady();
    return ModelStatus(ready: true, modelName: fileName);
  }

  // -------------------------------------------------------------------------
  // Install dari network / file
  // -------------------------------------------------------------------------

  /// Mengunduh [option] dari HuggingFace dengan progress.
  ///
  /// `true` bila model terpasang dan aktif.
  Future<bool> installFromNetwork(ModelOption option, {String? hfToken}) async {
    final previous = state.value;
    state = const AsyncLoading();
    final token = _cancelToken = edge_ai.CancelToken();
    final done = _installDone = Completer<void>();
    try {
      await _installFromNetwork(option, hfToken: hfToken, token: token);
      return true;
    } catch (e, st) {
      final kind = classifyModelError(e);
      if (!ref.mounted) return false;
      if (kind == ModelErrorKind.cancelled) {
        state = AsyncData(previous ?? const ModelStatus());
      } else {
        state = AsyncError(ModelException(kind, e), st);
      }
      return false;
    } finally {
      _cancelToken = null;
      if (!done.isCompleted) done.complete();
      if (identical(_installDone, done)) _installDone = null;
    }
  }

  /// Memasang model dari file lokal (upload pengguna).
  ///
  /// `true` bila model terpasang dan aktif.
  Future<bool> installFromFile(String path, ModelOption option) async {
    final previous = state.value;
    state = const AsyncLoading();
    _cancelToken = null;
    try {
      await edge_ai.FlutterEdgeAi.installModel(
        modelType: option.edgeAiModelType,
        fileType: option.edgeAiFileType,
      ).fromFile(path).install();

      await _activate(option.fileName);
      await _persistSelection(fileName: option.fileName, source: 'file', url: '');
      if (ref.mounted) {
        state = AsyncData(ModelStatus(ready: true, modelName: option.fileName));
      }
      return true;
    } catch (e, st) {
      final kind = classifyModelError(e);
      if (!ref.mounted) return false;
      if (kind == ModelErrorKind.cancelled) {
        state = AsyncData(previous ?? const ModelStatus());
      } else {
        state = AsyncError(ModelException(kind, e), st);
      }
      return false;
    }
  }

  /// Membatalkan download yang sedang berjalan dan menunggu proses berhenti.
  Future<void> cancelDownload() async {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('User cancelled download');
    }
    final done = _installDone;
    if (done != null && !done.isCompleted) {
      await done.future;
    }
  }

  // -------------------------------------------------------------------------
  // Private
  // -------------------------------------------------------------------------

  Future<void> _installFromNetwork(
    ModelOption option, {
    String? hfToken,
    required edge_ai.CancelToken token,
  }) async {
    await edge_ai.FlutterEdgeAi.installModel(
      modelType: option.edgeAiModelType,
      fileType: option.edgeAiFileType,
    )
        .fromNetwork(option.url, token: hfToken)
        .withCancelToken(token)
        .withProgress((progress) {
          if (!ref.mounted) return;
          state = AsyncData(
            (state.value ?? const ModelStatus()).copyWith(
              progress: progress / 100,
              installing: true,
              modelName: option.name,
            ),
          );
        })
        .install();

    await _activate(option.fileName);
    await _persistSelection(fileName: option.fileName, source: 'network', url: option.url);
    if (ref.mounted) {
      state = AsyncData(ModelStatus(ready: true, modelName: option.fileName));
    }
  }

  /// Menyimpan identitas model aktif ke [AppSettings].
  Future<void> _persistSelection({
    required String fileName,
    required String source,
    required String url,
  }) async {
    if (!ref.mounted) return;
    final settings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).save(
      settings.copyWith(
        modelVariant: fileName,
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

  // -------------------------------------------------------------------------
  // Inference
  // -------------------------------------------------------------------------

  /// Menghentikan generasi yang sedang berjalan. Tidak pernah melempar.
  Future<void> stopGeneration() async {
    try {
      await _activeChat?.stopGeneration();
    } catch (e) {
      AppLogger.debug('stopGeneration ignored', e);
    }
  }

  /// Streaming token untuk [fullPrompt].
  ///
  /// [isCancelled] dicek setelah antrean inferensi didapat: bila `true`, tidak
  /// ada generasi yang dimulai.
  Stream<String> generateResponseStream(
    String fullPrompt, {
    bool Function()? isCancelled,
  }) async* {
    final model = _model;
    if (model == null) throw StateError('Model not initialized');

    await _acquire();
    try {
      if (isCancelled?.call() == true) return;

      final chat = await model.openChat(
        temperature: 0.9,
        randomSeed: Random().nextInt(1 << 31),
        topK: 50,
        topP: 0.95,
        maxOutputTokens: 512,
      );
      _activeChat = chat;
      try {
        await chat.addQueryChunk(edge_ai.Message.text(text: fullPrompt, isUser: true));

        await for (final chunk in chat.generateChatResponseAsync()) {
          if (chunk is edge_ai.TextResponse) {
            yield chunk.token;
          }
        }
      } finally {
        _activeChat = null;
        await chat.close();
      }
    } on edge_ai.ContextLimitException {
      throw const ContextLimitReachedException();
    } finally {
      _release();
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

  // -------------------------------------------------------------------------
  // Generation lock
  // -------------------------------------------------------------------------

  Future<void> _acquire() async {
    final previous = _lockHeld;
    final completer = Completer<void>();
    _lockHeld = completer;
    if (previous != null) await previous.future;
  }

  void _release() {
    final held = _lockHeld;
    _lockHeld = null;
    if (held != null && !held.isCompleted) held.complete();
  }
}

final modelServiceProvider = AsyncNotifierProvider<ModelServiceNotifier, ModelStatus>(
  ModelServiceNotifier.new,
);

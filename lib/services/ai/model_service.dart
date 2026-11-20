import 'dart:async';
import 'dart:math';

import 'package:flutter_edge_ai/flutter_edge_ai.dart' as edge_ai;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genkit/genkit.dart' as gk;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_logger.dart';
import '../../core/utils/async_fifo_lock.dart';
import '../../models/ai_provider_profile.dart';
import '../../models/app_settings.dart';
import '../../models/message.dart';
import 'ai_provider_controller.dart';
import 'genkit/genkit_cloud_client.dart';
import 'model_catalog.dart';
import 'model_ready_provider.dart';
import 'prompt_builder.dart';
import 'secret_store.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

/// Jenis kegagalan pemasangan/pemuatan/inferensi model (lokal maupun cloud).
enum ModelErrorKind {
  network,
  auth,
  notFound,
  rateLimited,
  storage,
  invalidFile,
  engine,
  cancelled,
  timeout,
  invalidConfig,
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
/// Dilempar oleh [ModelServiceNotifier.generateResponseStream] atau
/// [ModelServiceNotifier.generateChatStream] agar lapisan fitur tidak perlu
/// mengimpor exception engine.
class ContextLimitReachedException implements Exception {
  const ContextLimitReachedException();

  @override
  String toString() => 'ContextLimitReachedException';
}

/// Mengecek apakah pesan error cloud menandakan batas context window terlampaui.
bool _looksLikeContextLimit(String lowerMessage) {
  return lowerMessage.contains('context_length_exceeded') ||
      lowerMessage.contains('maximum context length') ||
      lowerMessage.contains('prompt is too long') ||
      lowerMessage.contains('exceeds the maximum number of tokens') ||
      lowerMessage.contains('token limit exceeded');
}

/// Mengklasifikasikan error engine/IO/Genkit ke [ModelErrorKind] yang bisa ditampilkan.
///
/// Fungsi murni (tidak menyentuh provider) supaya bisa diuji terpisah.
ModelErrorKind classifyModelError(Object error) {
  if (error is ModelException) return error.kind;
  if (error is ContextLimitReachedException) return ModelErrorKind.engine;
  if (error is TimeoutException) return ModelErrorKind.timeout;
  if (error is gk.CancelledException) return ModelErrorKind.cancelled;
  if (error is gk.GenkitException) {
    final lower = error.message.toLowerCase();
    if (_looksLikeContextLimit(lower)) return ModelErrorKind.engine;
    return switch (error.status) {
      gk.StatusCode.cancelled => ModelErrorKind.cancelled,
      gk.StatusCode.unauthenticated ||
      gk.StatusCode.permissionDenied => ModelErrorKind.auth,
      gk.StatusCode.notFound => ModelErrorKind.notFound,
      gk.StatusCode.resourceExhausted => ModelErrorKind.rateLimited,
      gk.StatusCode.deadlineExceeded => ModelErrorKind.timeout,
      gk.StatusCode.invalidArgument ||
      gk.StatusCode.outOfRange ||
      gk.StatusCode.failedPrecondition => ModelErrorKind.invalidConfig,
      gk.StatusCode.unavailable => ModelErrorKind.network,
      _ => _classifyByMessage(error.message),
    };
  }
  if (error is StateError) return ModelErrorKind.engine;
  return _classifyByMessage(error.toString());
}

ModelErrorKind _classifyByMessage(String raw) {
  final message = raw.toLowerCase();
  if (message.contains('cancel')) return ModelErrorKind.cancelled;
  if (message.contains('timed out') || message.contains('timeout')) {
    return ModelErrorKind.timeout;
  }
  if (message.contains('404') || message.contains('not found')) {
    return ModelErrorKind.notFound;
  }
  if (message.contains('401') ||
      message.contains('403') ||
      message.contains('unauthorized') ||
      message.contains('forbidden') ||
      message.contains('invalid api key') ||
      message.contains('api key is missing') ||
      message.contains('authentication')) {
    return ModelErrorKind.auth;
  }
  if (message.contains('429') ||
      message.contains('rate limit') ||
      message.contains('too many') ||
      message.contains('quota')) {
    return ModelErrorKind.rateLimited;
  }
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('host lookup') ||
      message.contains('handshake')) {
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
  return ModelErrorKind.unknown;
}

/// Status model LLM aktif (lokal on-device maupun Cloud BYOK).
class ModelStatus {
  /// Model siap inferensi.
  final bool ready;

  /// Progress download 0..1 (hanya relevan saat download lokal berlangsung).
  final double progress;

  /// Nama model aktif (null bila belum ada).
  final String? modelName;

  /// Sedang mengunduh/memasang model lokal.
  final bool installing;

  /// Mode eksekusi aktif (`AiMode.local` / `AiMode.cloud`).
  final AiMode mode;

  /// Nama profil/provider cloud aktif (null saat mode lokal).
  final String? providerLabel;

  const ModelStatus({
    this.ready = false,
    this.progress = 0,
    this.modelName,
    this.installing = false,
    this.mode = AiMode.local,
    this.providerLabel,
  });

  ModelStatus copyWith({
    bool? ready,
    double? progress,
    String? modelName,
    bool? installing,
    AiMode? mode,
    String? providerLabel,
    bool clearProviderLabel = false,
  }) {
    return ModelStatus(
      ready: ready ?? this.ready,
      progress: progress ?? this.progress,
      modelName: modelName ?? this.modelName,
      installing: installing ?? this.installing,
      mode: mode ?? this.mode,
      providerLabel: clearProviderLabel
          ? null
          : (providerLabel ?? this.providerLabel),
    );
  }
}

/// Riverpod notifier yang mengelola siklus hidup model LLM **Hybrid**:
///
/// - **Local On-Device (`AiMode.local`)** via `flutter_edge_ai` (download
///   HuggingFace, upload file `.litertlm`/`.task`, atau model terpasang).
/// - **Cloud BYOK (`AiMode.cloud`)** via **Genkit Dart** (`googleAI`,
///   `anthropic`, `openAI` + custom `baseUrl` & parameter penuh per profil).
class ModelServiceNotifier extends AsyncNotifier<ModelStatus> {
  /// Menserialisasikan siklus hidup native model lintas dispose/rebuild
  /// sehingga instance baru tidak membuka model sebelum instance lama ditutup.
  static Future<void> _engineTransition = Future<void>.value();

  edge_ai.InferenceModel? _model;
  edge_ai.CancelToken? _cancelToken;

  /// Chat lokal yang sedang aktif — dipakai [stopGeneration].
  edge_ai.InferenceChat? _activeChat;

  /// Controller pembatalan Genkit Cloud yang sedang aktif — dipakai [stopGeneration].
  gk.CancellationController? _activeCloudCancel;

  bool _generationCancelled = false;
  bool _disposed = false;

  /// Selesai saat proses install (sukses/gagal/batal) berakhir.
  Completer<void>? _installDone;
  bool _installInFlight = false;

  /// Antrean inferensi lokal: chat, ekstraksi memori, ringkasan, dan pergantian
  /// model tidak boleh berjalan bersamaan pada instance engine native yang sama.
  final AsyncFifoLock _inferenceLock = AsyncFifoLock();

  static Future<void> _enqueueTransition(Future<void> Function() action) {
    final next = _engineTransition.then((_) => action(), onError: (_) => action());
    _engineTransition = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  Future<ModelStatus> build() async {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _cancelToken?.cancel('provider disposed');
      _activeCloudCancel?.cancel('provider disposed');
      _activeCloudCancel = null;
      _generationCancelled = true;
      final chat = _activeChat;
      _activeChat = null;
      final model = _model;
      _model = null;
      _enqueueTransition(() async {
        if (chat != null) {
          try {
            await chat.stopGeneration();
          } catch (e) {
            AppLogger.debug('Dispose stopGeneration ignored', e);
          }
          try {
            await chat.close();
          } catch (e) {
            AppLogger.debug('Dispose chat close ignored', e);
          }
        }
        if (model != null) {
          try {
            await model.close();
          } catch (e) {
            AppLogger.debug('Dispose model close ignored', e);
          }
        }
      });
    });

    await _engineTransition;
    if (_disposed || !ref.mounted) return const ModelStatus();

    final settings = ref.read(appSettingsProvider);

    // ── Mode Cloud BYOK ────────────────────────────────────────────────────
    if (settings.aiMode == AiMode.cloud) {
      return _activateCloudFromSettings();
    }

    // ── Mode Lokal On-Device ───────────────────────────────────────────────
    if (settings.modelVariant.isNotEmpty) {
      if (!await edge_ai.FlutterEdgeAi.isModelInstalled(settings.modelVariant)) {
        if (ref.mounted) ref.read(modelReadyProvider.notifier).reset();
        return const ModelStatus(mode: AiMode.local);
      }
      return _activateLocal(settings.modelVariant);
    }

    // Belum pernah memilih model. Hanya pakai otomatis bila tepat satu file
    // terpasang (daftar juga memuat model TTS/STT, jadi >1 tidak bisa ditebak).
    try {
      final installed = await edge_ai.FlutterEdgeAi.listInstalledModels();
      if (installed.length != 1) return const ModelStatus(mode: AiMode.local);
      final fileName = installed.first;
      try {
        final status = await _activateLocal(fileName);
        await _persistLocalSelection(
          fileName: fileName,
          source: 'file',
          url: '',
        );
        return status;
      } catch (e) {
        // File bisa jadi model suara — jangan blokir startup.
        AppLogger.debug('Auto-activate skipped', e);
        return const ModelStatus(mode: AiMode.local);
      }
    } catch (e) {
      AppLogger.debug('Installed model scan skipped', e);
      return const ModelStatus(mode: AiMode.local);
    }
  }

  Future<ModelStatus> _activateCloudFromSettings() async {
    final profile = ref.read(activeCloudProfileProvider);
    if (profile == null || profile.modelId.trim().isEmpty) {
      if (ref.mounted) ref.read(modelReadyProvider.notifier).reset();
      return const ModelStatus(ready: false, mode: AiMode.cloud);
    }

    final usable = await ref
        .read(aiProviderProfilesProvider.notifier)
        .hasUsableCredentials(profile);
    if (!ref.mounted || _disposed) return const ModelStatus(mode: AiMode.cloud);

    if (!usable) {
      ref.read(modelReadyProvider.notifier).reset();
      return ModelStatus(
        ready: false,
        mode: AiMode.cloud,
        modelName: profile.modelId,
        providerLabel: profile.name,
      );
    }

    ref.read(modelReadyProvider.notifier).setReady();
    return ModelStatus(
      ready: true,
      mode: AiMode.cloud,
      modelName: profile.modelId,
      providerLabel: profile.name,
    );
  }

  Future<ModelStatus> _activateLocal(String fileName) async {
    await stopGeneration();
    return _inferenceLock.run(() async {
      await _engineTransition;
      if (_disposed || !ref.mounted) return const ModelStatus();

      await _closeLocalModelLocked();

      late final edge_ai.InferenceModel loaded;
      try {
        loaded = await edge_ai.FlutterEdgeAi.getActiveModel(
          preferredBackend: edge_ai.PreferredBackend.cpu,
          maxTokens: 2048,
        );
      } catch (e) {
        if (ref.mounted) ref.read(modelReadyProvider.notifier).reset();
        throw ModelException(ModelErrorKind.engine, e);
      }

      if (_disposed || !ref.mounted) {
        try {
          await loaded.close();
        } catch (e) {
          AppLogger.debug('Discarded model close ignored', e);
        }
        return const ModelStatus();
      }

      _model = loaded;
      ref.read(modelReadyProvider.notifier).setReady();
      return ModelStatus(
        ready: true,
        modelName: fileName,
        mode: AiMode.local,
      );
    });
  }

  Future<void> _closeLocalModelLocked() async {
    final oldModel = _model;
    _model = null;
    if (oldModel != null) {
      try {
        await oldModel.close();
      } catch (e) {
        AppLogger.debug('Previous model close ignored', e);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Switch mode Cloud BYOK <-> Local
  // -------------------------------------------------------------------------

  /// Mengaktifkan profil Cloud BYOK [profile] dan membebaskan RAM model lokal.
  Future<bool> activateCloudProfile(
    AiProviderProfile profile, {
    String? apiKey,
  }) async {
    await cancelDownload();
    await stopGeneration();
    if (!ref.mounted || _disposed) return false;

    final saved = await ref
        .read(aiProviderProfilesProvider.notifier)
        .saveProfile(profile, apiKey: apiKey);
    if (!ref.mounted || _disposed) return false;

    final usable = await ref
        .read(aiProviderProfilesProvider.notifier)
        .hasUsableCredentials(saved);
    if (!ref.mounted || _disposed) return false;

    if (!usable || saved.modelId.trim().isEmpty) {
      state = AsyncError(
        const ModelException(ModelErrorKind.auth),
        StackTrace.current,
      );
      return false;
    }

    // Bebaskan RAM dari model native lokal bila sebelumnya sedang termuat.
    await _inferenceLock.run(() async {
      await _closeLocalModelLocked();
    });
    if (!ref.mounted || _disposed) return false;

    final currentSettings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).save(
      currentSettings.copyWith(
        aiMode: AiMode.cloud,
        activeCloudProfileId: saved.id,
      ),
    );

    ref.read(modelReadyProvider.notifier).setReady();
    state = AsyncData(
      ModelStatus(
        ready: true,
        mode: AiMode.cloud,
        modelName: saved.modelId,
        providerLabel: saved.name,
      ),
    );
    return true;
  }

  /// Beralih kembali ke mode Lokal On-Device.
  ///
  /// Mengembalikan `true` jika model lokal yang dipilih sebelumnya sudah
  /// terpasang dan langsung berhasil diaktifkan.
  Future<bool> switchToLocalMode() async {
    await stopGeneration();
    if (!ref.mounted || _disposed) return false;

    final settings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).save(
      settings.copyWith(aiMode: AiMode.local),
    );

    if (settings.modelVariant.isNotEmpty &&
        await edge_ai.FlutterEdgeAi.isModelInstalled(settings.modelVariant)) {
      try {
        final status = await _activateLocal(settings.modelVariant);
        if (ref.mounted) state = AsyncData(status);
        return status.ready;
      } catch (e, st) {
        if (ref.mounted) {
          ref.read(modelReadyProvider.notifier).reset();
          state = AsyncError(ModelException(classifyModelError(e), e), st);
        }
        return false;
      }
    }

    if (ref.mounted) {
      ref.read(modelReadyProvider.notifier).reset();
      state = const AsyncData(ModelStatus(ready: false, mode: AiMode.local));
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Install model lokal dari network / file
  // -------------------------------------------------------------------------

  /// Mengunduh [option] dari HuggingFace dengan progress lalu mengaktifkannya
  /// di mode Lokal.
  Future<bool> installFromNetwork(ModelOption option, {String? hfToken}) async {
    if (_installInFlight) return false;
    _installInFlight = true;
    final previous = state.value;
    state = AsyncData(
      (previous ?? const ModelStatus()).copyWith(
        installing: true,
        progress: 0,
        modelName: option.name,
        mode: AiMode.local,
        clearProviderLabel: true,
      ),
    );
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
      if (identical(_cancelToken, token)) _cancelToken = null;
      if (!done.isCompleted) done.complete();
      if (identical(_installDone, done)) _installDone = null;
      _installInFlight = false;
    }
  }

  /// Memasang model dari file lokal (upload pengguna) lalu mengaktifkannya.
  Future<bool> installFromFile(String path, ModelOption option) async {
    if (_installInFlight) return false;
    _installInFlight = true;
    final previous = state.value;
    state = AsyncData(
      ModelStatus(
        ready: previous?.ready ?? false,
        progress: 0,
        modelName: option.name,
        installing: true,
        mode: AiMode.local,
      ),
    );
    _cancelToken = null;
    try {
      await edge_ai.FlutterEdgeAi.installModel(
        modelType: option.edgeAiModelType,
        fileType: option.edgeAiFileType,
      ).fromFile(path).install();

      await _activateLocal(option.fileName);
      await _persistLocalSelection(
        fileName: option.fileName,
        source: 'file',
        url: '',
      );
      if (ref.mounted) {
        state = AsyncData(
          ModelStatus(
            ready: true,
            modelName: option.fileName,
            mode: AiMode.local,
          ),
        );
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
    } finally {
      _installInFlight = false;
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

    await _activateLocal(option.fileName);
    await _persistLocalSelection(
      fileName: option.fileName,
      source: 'network',
      url: option.url,
    );
    if (ref.mounted) {
      state = AsyncData(
        ModelStatus(
          ready: true,
          modelName: option.fileName,
          mode: AiMode.local,
        ),
      );
    }
  }

  /// Menyimpan identitas model lokal aktif + menyetel `aiMode = AiMode.local`.
  Future<void> _persistLocalSelection({
    required String fileName,
    required String source,
    required String url,
  }) async {
    if (!ref.mounted) return;
    final settings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).save(
      settings.copyWith(
        aiMode: AiMode.local,
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
  // Inference (Hybrid Local + Cloud BYOK)
  // -------------------------------------------------------------------------

  /// Menghentikan generasi yang sedang berjalan (lokal maupun cloud).
  /// Tidak pernah melempar.
  Future<void> stopGeneration() async {
    _generationCancelled = true;
    final cloudCancel = _activeCloudCancel;
    if (cloudCancel != null && !cloudCancel.isCancelled) {
      cloudCancel.cancel('User stopped generation');
    }
    try {
      await _activeChat?.stopGeneration();
    } catch (e) {
      AppLogger.debug('stopGeneration ignored', e);
    }
  }

  /// Streaming chat hybrid:
  /// - **Cloud mode**: mengirim multi-turn terstruktur lewat Genkit Cloud Client
  ///   dengan seluruh parameter profil aktif.
  /// - **Local mode**: menyusun prompt datar berbatas lalu mendelegasikan ke
  ///   [generateResponseStream].
  Stream<String> generateChatStream({
    required String systemPrompt,
    required List<Message> history,
    required String latestUserInput,
    bool Function()? isCancelled,
  }) async* {
    final settings = ref.read(appSettingsProvider);
    if (settings.aiMode != AiMode.cloud) {
      final fullPrompt = PromptBuilder.buildFullPrompt(
        systemPrompt,
        history,
        latestUserInput,
      );
      yield* generateResponseStream(fullPrompt, isCancelled: isCancelled);
      return;
    }

    if (_disposed || isCancelled?.call() == true) return;
    final profile = ref.read(activeCloudProfileProvider);
    if (profile == null) {
      throw const ModelException(ModelErrorKind.invalidConfig);
    }

    final apiKey = await ref
        .read(secretStoreProvider)
        .read(SecretKeys.forLlmProfile(profile.profileKey));
    if (_disposed || isCancelled?.call() == true) return;

    final limits = PromptLimits.fromCloudProfile(profile);
    final turns = PromptBuilder.buildCloudMessages(
      history,
      latestUserInput,
      limits: limits,
    );

    _generationCancelled = false;
    final cancelCtrl = gk.CancellationController();
    _activeCloudCancel = cancelCtrl;

    try {
      final client = ref.read(genkitCloudClientProvider);
      await for (final token in client.streamChat(
        profile: profile,
        apiKey: apiKey ?? '',
        systemPrompt: systemPrompt,
        messages: turns,
        cancellation: cancelCtrl,
      )) {
        if (_disposed || _generationCancelled || isCancelled?.call() == true) {
          cancelCtrl.cancel('Cancelled by caller');
          break;
        }
        yield token;
      }
    } on ContextLimitReachedException {
      rethrow;
    } catch (e) {
      if (_generationCancelled || isCancelled?.call() == true) return;
      final lower = e.toString().toLowerCase();
      if (_looksLikeContextLimit(lower)) {
        throw const ContextLimitReachedException();
      }
      throw ModelException(classifyModelError(e), e);
    } finally {
      if (identical(_activeCloudCancel, cancelCtrl)) {
        _activeCloudCancel = null;
      }
    }
  }

  /// Generasi teks latar belakang (ekstraksi memori & ringkasan percakapan).
  ///
  /// Pada mode Cloud: menghormati `profile.enableBackgroundTasks` (jika `false`,
  /// mengembalikan string kosong tanpa panggilan API) dan memakai
  /// `profile.backgroundModelId` bila disetel.
  Future<String> generateBackgroundResponse(String prompt) async {
    final settings = ref.read(appSettingsProvider);
    if (settings.aiMode != AiMode.cloud) {
      return generateResponse(prompt);
    }

    final profile = ref.read(activeCloudProfileProvider);
    if (profile == null || !profile.enableBackgroundTasks) return '';

    final apiKey = await ref
        .read(secretStoreProvider)
        .read(SecretKeys.forLlmProfile(profile.profileKey));

    try {
      final client = ref.read(genkitCloudClientProvider);
      return await client.generateText(
        profile: profile,
        apiKey: apiKey ?? '',
        prompt: prompt,
        modelOverride: profile.backgroundModelId.isNotEmpty
            ? profile.backgroundModelId
            : null,
        maxOutputTokensOverride: 512,
        temperatureOverride: 0.2,
        disableThinking: true,
      );
    } catch (e) {
      AppLogger.debug('Cloud background task skipped', e);
      return '';
    }
  }

  /// Streaming token lokal untuk [fullPrompt].
  ///
  /// [isCancelled] dicek setelah antrean inferensi didapat: bila `true`, tidak
  /// ada generasi yang dimulai.
  Stream<String> generateResponseStream(
    String fullPrompt, {
    bool Function()? isCancelled,
  }) async* {
    final release = await _inferenceLock.acquire();
    try {
      if (_disposed || isCancelled?.call() == true) return;
      final model = _model;
      if (model == null) throw StateError('Model not initialized');

      _generationCancelled = false;
      final chat = await model.openChat(
        temperature: 0.9,
        randomSeed: Random().nextInt(1 << 31),
        topK: 50,
        topP: 0.95,
        maxOutputTokens: 512,
      );
      if (_disposed || _generationCancelled || isCancelled?.call() == true) {
        try {
          await chat.close();
        } catch (e) {
          AppLogger.debug('Cancelled chat.close ignored', e);
        }
        return;
      }
      _activeChat = chat;
      try {
        await chat.addQueryChunk(
          edge_ai.Message.text(text: fullPrompt, isUser: true),
        );

        await for (final chunk in chat.generateChatResponseAsync()) {
          if (chunk is edge_ai.TextResponse) {
            yield chunk.token;
          }
        }
      } finally {
        if (identical(_activeChat, chat)) _activeChat = null;
        try {
          await chat.close();
        } catch (e) {
          AppLogger.debug('chat.close ignored', e);
        }
      }
    } on edge_ai.ContextLimitException {
      throw const ContextLimitReachedException();
    } finally {
      release();
    }
  }

  /// Mengumpulkan semua token streaming lokal menjadi satu string.
  Future<String> generateResponse(String fullPrompt) async {
    final buffer = StringBuffer();
    await for (final token in generateResponseStream(fullPrompt)) {
      buffer.write(token);
    }
    return buffer.toString();
  }
}

final modelServiceProvider =
    AsyncNotifierProvider<ModelServiceNotifier, ModelStatus>(
      ModelServiceNotifier.new,
    );

import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/model_ready_provider.dart';

/// Riverpod notifier that owns the on-device LLM lifecycle.
///
/// State is `true` when the model is ready for inference, `false` (or loading /
/// error) otherwise.  Consumers read [modelServiceProvider] to track readiness
/// and call [generateResponseStream] / [generateResponse] for inference.
class ModelServiceNotifier extends AsyncNotifier<bool> {
  static const String _modelAssetPath = 'models/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task';

  /// Soft cap on the number of characters supplied as context per request.
  static const int maxContextChars = 6000;

  gemma.InferenceModel? _model;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  Future<bool> build() => _initializeWithRetry();

  Future<bool> _initializeWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final plugin = gemma.FlutterGemmaPlugin.instance;

        await gemma.FlutterGemma.installModel(
          modelType: gemma.ModelType.gemmaIt,
        ).fromAsset(_modelAssetPath).install();

        _model = await plugin.createModel(
          modelType: gemma.ModelType.gemmaIt,
          preferredBackend: gemma.PreferredBackend.cpu,
          maxTokens: 2048,
        );

        ref.read(modelReadyProvider.notifier).state = true;
        return true;
      } catch (e) {
        if (attempt == maxRetries) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Inference
  // -------------------------------------------------------------------------

  /// Streams response tokens for [fullPrompt].
  ///
  /// A fresh [gemma.InferenceChat] is created per call so that consecutive
  /// requests do not share native session state.  [fullPrompt] should be built
  /// by [PromptBuilder.buildFullPrompt].
  Stream<String> generateResponseStream(String fullPrompt) async* {
    final model = _model;
    if (model == null) throw StateError('Model not initialized');

    final chat = await model.createChat(temperature: 0.7, randomSeed: 42, topK: 40, topP: 0.9);

    await chat.addQueryChunk(gemma.Message.text(text: fullPrompt, isUser: true));

    await for (final chunk in chat.generateChatResponseAsync()) {
      if (chunk is gemma.TextResponse) {
        yield chunk.token;
      }
    }
  }

  /// Collects all streamed tokens and returns the complete response string.
  Future<String> generateResponse(String fullPrompt) async {
    final buffer = StringBuffer();
    await for (final token in generateResponseStream(fullPrompt)) {
      buffer.write(token);
    }
    return buffer.toString();
  }

  // -------------------------------------------------------------------------
  // Reset / recovery
  // -------------------------------------------------------------------------

  /// Disposes the current model and reinitializes from scratch.
  Future<void> reset() async {
    _model = null;
    ref.read(modelReadyProvider.notifier).state = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_initializeWithRetry);
  }
}

final modelServiceProvider = AsyncNotifierProvider<ModelServiceNotifier, bool>(
  ModelServiceNotifier.new,
);

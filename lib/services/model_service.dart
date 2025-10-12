import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';

class ModelService {
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  FlutterGemmaPlugin? _gemma;
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _errorMessage;
  DateTime? _lastInitializedTime;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastInitializedTime => _lastInitializedTime;

  // Maximum tokens for context to prevent exceeding model capacity
  static const int maxContextTokens = 2000;

  // Stream controller for model initialization status
  static final StreamController<bool> _initializationStatusController =
      StreamController<bool>.broadcast();
  static Stream<bool> get initializationStatus => _initializationStatusController.stream;

  Future<bool> initializeModel() async {
    // If already initialized, return true
    if (_isInitialized) {
      print('Model already initialized at $_lastInitializedTime');
      return true;
    }

    // If currently initializing, wait for it to complete
    if (_isInitializing) {
      print('Model initialization already in progress, waiting...');
      // Wait for initialization to complete
      await for (final status in _initializationStatusController.stream) {
        if (status) {
          return true;
        }
        if (_errorMessage != null) {
          return false;
        }
      }
      return false;
    }

    try {
      _isInitializing = true;
      _errorMessage = null;
      _initializationStatusController.add(false); // Notify that initialization is in progress

      // Initialize the plugin
      _gemma = FlutterGemmaPlugin.instance;

      // Try different model paths in order of preference
      final modelPath = 'models/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task';

      bool modelLoaded = false;
      String? lastError;

      try {
        // Use the new FlutterGemma API
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromAsset(modelPath).install();

        // Try to create a model
        _model = await _gemma!.createModel(
          modelType: ModelType.gemmaIt,
          preferredBackend: PreferredBackend.cpu,
          maxTokens: 2048,
        );

        // Create chat session
        _chat = await _model!.createChat(temperature: 0.7, randomSeed: 42, topK: 40, topP: 0.9);

        _isInitialized = true;
        _lastInitializedTime = DateTime.now();
        modelLoaded = true;
        print('Model initialized successfully with: $modelPath at $_lastInitializedTime');

        // Notify that initialization is complete
        _initializationStatusController.add(true);
      } catch (e) {
        lastError = 'Failed to load $modelPath: ${e.toString()}';
        print('Model loading error for $modelPath: $e');
        _model = null;
        _chat = null;

        // Notify that initialization failed
        _initializationStatusController.add(false);
      }

      if (!modelLoaded) {
        _errorMessage = 'Failed to load any available model. Last error: $lastError';
        print('All model loading attempts failed');
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to initialize model: ${e.toString()}';
      print('Model initialization error: $e');

      // Notify that initialization failed
      _initializationStatusController.add(false);
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  // Method to check if model needs initialization
  bool needsInitialization() {
    return !_isInitialized && !_isInitializing;
  }

  // Method to retry initialization with delay
  Future<bool> retryInitialization({
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    if (_isInitialized) {
      return true;
    }

    for (int i = 0; i < maxRetries; i++) {
      print('Retrying model initialization (attempt ${i + 1}/$maxRetries)');

      try {
        final success = await initializeModel();
        if (success) {
          return true;
        }

        // Wait before retrying
        if (i < maxRetries - 1) {
          await Future.delayed(delay);
        }
      } catch (e) {
        print('Retry attempt ${i + 1} failed: $e');

        // Wait before retrying
        if (i < maxRetries - 1) {
          await Future.delayed(delay);
        }
      }
    }

    return false;
  }

  // Method to reset model state (for error recovery)
  Future<void> reset() async {
    print('Resetting model state');
    _chat = null;
    _model = null;
    _gemma = null;
    _isInitialized = false;
    _isInitializing = false;
    _lastInitializedTime = null;
    _errorMessage = null;
  }

  Future<String> generateResponse(
    String userMessage, {
    String? pdfContext,
    bool usePdfContext = true,
    double contextRatio = 0.7, // 70% of max tokens for context, 30% for response
  }) async {
    if (!_isInitialized || _chat == null) {
      throw Exception('Model not initialized');
    }

    try {
      // Combine user message with PDF context if available and enabled
      String finalPrompt = userMessage;

      if (usePdfContext && pdfContext != null && pdfContext.isNotEmpty) {
        // Limit context length to stay within token limits
        final int maxContextLength = (maxContextTokens * contextRatio).floor();
        String limitedContext = pdfContext;

        if (pdfContext.length > maxContextLength) {
          // Truncate context if it's too long
          limitedContext = pdfContext.substring(0, maxContextLength);
          print('Context truncated to $maxContextLength characters');
        }

        // Create a structured prompt with PDF context
        finalPrompt = _createPromptWithContext(userMessage, limitedContext);
      }

      // Add user message with context
      await _chat!.addQueryChunk(Message.text(text: finalPrompt, isUser: true));

      // Generate response
      String response = '';
      await for (final responseChunk in _chat!.generateChatResponseAsync()) {
        if (responseChunk is TextResponse) {
          response += responseChunk.token;
        }
      }

      print(
        'Generated response: ${response.substring(0, response.length < 100 ? response.length : 100)}...',
      );
      return response;
    } catch (e) {
      _errorMessage = 'Failed to generate response: ${e.toString()}';
      print('Response generation error: $e');
      throw Exception('Failed to generate response: ${e.toString()}');
    }
  }

  /// Create a structured prompt with PDF context
  String _createPromptWithContext(String userMessage, String pdfContext) {
    return '''
[ROLE]
You are an AI assistant specialized in answering questions based on provided document context.

[CONTEXT FROM PDF DOCUMENT]
$pdfContext

[INSTRUCTIONS]
Based on the PDF document context provided above, please answer the following question according to these guidelines:

1. If the information is directly available in the context, provide a clear and accurate answer.
2. If the information is not available in the context, explicitly state: "I don't have enough information from the document to answer this question accurately."
3. Always cite specific parts of the document when providing information by including relevant quotes or references.
4. Do not make up or infer information that is not explicitly stated in the document.
5. If the question is unrelated to the document context, politely explain that you can only answer questions related to the provided document.
6. Structure your response in a clear format with:
   - A direct answer to the question
   - Supporting evidence from the document (with quotes or specific references)
   - A brief explanation of how the evidence supports your answer

[QUESTION]
$userMessage

[RESPONSE FORMAT]
Please provide a structured response following this format:
1. Answer: [Your direct answer to the question]
2. Evidence: [Specific quotes or references from the document that support your answer]
3. Explanation: [Brief explanation of how the evidence supports your answer]

If the information is not available in the document, clearly state this instead of following the above format.
''';
  }

  Future<void> dispose() async {
    try {
      _chat = null;
      _model = null;
      _gemma = null;
      _isInitialized = false;
      _isInitializing = false;
      _lastInitializedTime = null;
    } catch (e) {
      print('Error disposing model: $e');
    }
  }
}

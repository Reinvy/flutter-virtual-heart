import 'package:flutter/material.dart';
import 'services/model_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ModelService _modelService = ModelService();
  
  bool _isGlobalLoading = false;
  String? _globalError;
  bool _isModelInitialized = false;
  DateTime? _lastInitializationAttempt;
  int _initializationRetryCount = 0;
  static const int _maxRetries = 3;

  bool get isGlobalLoading => _isGlobalLoading;
  bool get isModelInitialized => _isModelInitialized;
  String? get globalError => _globalError;
  ModelService get modelService => _modelService;
  DateTime? get lastInitializationAttempt => _lastInitializationAttempt;
  int get initializationRetryCount => _initializationRetryCount;
  int get maxRetries => _maxRetries;

  Future<void> initializeApp() async {
    if (_isGlobalLoading) return;
    
    _isGlobalLoading = true;
    _globalError = null;
    _lastInitializationAttempt = DateTime.now();
    notifyListeners();

    try {
      print('Initializing app and model...');
      final success = await _modelService.initializeModel();
      
      if (success) {
        _isModelInitialized = true;
        _initializationRetryCount = 0;
        print('App initialization completed successfully');
      } else {
        _globalError = _modelService.errorMessage ?? 'Failed to initialize model';
        print('App initialization failed: $_globalError');
        
        // Try to retry initialization
        if (_initializationRetryCount < _maxRetries) {
          _initializationRetryCount++;
          print('Attempting to retry model initialization ($_initializationRetryCount/$_maxRetries)...');
          await Future.delayed(const Duration(seconds: 2)); // Wait before retry
          final retrySuccess = await _modelService.retryInitialization();
          if (retrySuccess) {
            _isModelInitialized = true;
            _globalError = null;
            _initializationRetryCount = 0;
            print('Model initialization succeeded after retry');
          }
        } else {
          print('Maximum initialization retries reached');
        }
      }
    } catch (e) {
      _globalError = 'Error during app initialization: ${e.toString()}';
      print('App initialization error: $e');
    } finally {
      _isGlobalLoading = false;
      notifyListeners();
    }
  }

  void resetModel() async {
    _isModelInitialized = false;
    _globalError = null;
    _initializationRetryCount = 0;
    notifyListeners();
    
    await _modelService.reset();
    
    // Try to reinitialize
    await initializeApp();
  }

  void clearError() {
    _globalError = null;
    notifyListeners();
  }

  // Force retry initialization
  Future<void> forceRetryInitialization() async {
    _initializationRetryCount = 0;
    await initializeApp();
  }
}
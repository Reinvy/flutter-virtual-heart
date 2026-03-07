import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the on-device LLM model is loaded and ready for inference.
///
/// Set to `true` by [ModelService] (Phase 1.4) once the model is initialized.
/// The router guard uses this to redirect to [AppRoutes.modelDownload] if needed.
final modelReadyProvider = StateProvider<bool>((ref) => false);

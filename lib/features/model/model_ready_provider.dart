// Fitur Model (FR-04) — status kesiapan model AI.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Melacak apakah model LLM on-device sudah dimuat dan siap inferensi.
///
/// Diset `true` oleh [ModelServiceNotifier] setelah model terinisialisasi.
/// Router guard memakai ini untuk redirect ke [AppRoutes.modelDownload].
final modelReadyProvider = StateProvider<bool>((ref) => false);

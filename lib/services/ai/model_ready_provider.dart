// Fitur Model (FR-04) — status kesiapan model AI.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Melacak apakah model LLM on-device sudah dimuat dan siap inferensi.
///
/// Diset `true` oleh [ModelServiceNotifier] setelah model terinisialisasi.
/// Router guard memakai ini untuk redirect ke [AppRoutes.modelDownload].
///
/// Menggantikan `StateProvider` (tidak diekspos lagi di Riverpod 3) dengan
/// [Notifier] yang state-nya diubah lewat [setReady]/[reset].
class ModelReadyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setReady() => state = true;

  void reset() => state = false;
}

final modelReadyProvider =
    NotifierProvider<ModelReadyNotifier, bool>(ModelReadyNotifier.new);
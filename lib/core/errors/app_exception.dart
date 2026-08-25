// Pengecualian aplikasi & mapper (docs/DESIGN.md §6.2)
import 'app_logger.dart';

/// Pengecualian domain dengan pesan ramah (non-teknis) untuk UI.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Pesan ramah yang aman ditampilkan ke pengguna.
  final String message;

  /// Penyebab teknis (untuk log, bukan untuk UI).
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}

/// Memetakan error tak dikenal ke [AppException] dengan pesan ramah.
AppException mapError(Object error, {StackTrace? stack}) {
  if (error is AppException) return error;
  AppLogger.error('Unexpected error', error, stack);
  return const AppException('Terjadi kesalahan. Silakan coba lagi.');
}

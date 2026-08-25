// Penanganan error terpusat (docs/DESIGN.md §6.2 & AGENTS.md §5)
//
// Aturan: jangan `print`/`debugPrint` sembarangan di kode produksi — gunakan
// [AppLogger]. UI menampilkan pesan hangat dari [AppStrings], bukan teks error
// teknis.
import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  AppLogger._();

  static void debug(String message, [Object? error]) {
    if (kDebugMode) debugPrint('[VH][debug] $message${error == null ? '' : ' → $error'}');
  }

  static void info(String message) {
    if (kDebugMode) debugPrint('[VH][info] $message');
  }

  static void warn(String message, [Object? error]) {
    debugPrint('[VH][warn] $message${error == null ? '' : ' → $error'}');
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    debugPrint('[VH][error] $message${error == null ? '' : ' → $error'}');
    if (stack != null && kDebugMode) debugPrint('$stack');
  }
}

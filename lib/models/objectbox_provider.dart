// Provider ObjectBox — menyediakan ObjectBoxService ke seluruh app.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database/objectbox_service.dart';

/// Menyediakan instance [ObjectBoxService] yang sudah diinisialisasi.
///
/// Harus di-override via [ProviderScope] di [main] setelah
/// `await ObjectBoxService.create()`.
final objectBoxServiceProvider = Provider<ObjectBoxService>(
  (_) => throw UnimplementedError('objectBoxServiceProvider must be overridden in main()'),
);

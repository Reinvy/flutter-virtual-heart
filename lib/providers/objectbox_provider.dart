import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/objectbox_service.dart';

/// Provides the initialized [ObjectBoxService] instance.
///
/// Must be overridden via [ProviderScope] overrides in [main] after
/// awaiting [ObjectBoxService.create()].
final objectBoxServiceProvider = Provider<ObjectBoxService>(
  (_) => throw UnimplementedError('objectBoxServiceProvider must be overridden in main()'),
);

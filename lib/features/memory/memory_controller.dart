// Fitur Memory (FR-11, FR-12) — controller daftar fakta memori.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/memory_fact.dart';
import '../../models/objectbox_provider.dart';

/// Daftar reaktif semua [MemoryFact], diurutkan terbaru dulu.
class MemoryFactsNotifier extends Notifier<List<MemoryFact>> {
  @override
  List<MemoryFact> build() => _load();

  List<MemoryFact> _load() {
    final db = ref.read(objectBoxServiceProvider);
    return db.memoryFactBox.getAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void deleteFact(int id) {
    ref.read(objectBoxServiceProvider).memoryFactBox.remove(id);
    state = state.where((f) => f.id != id).toList();
  }

  void resetAll() {
    ref.read(objectBoxServiceProvider).memoryFactBox.removeAll();
    state = const [];
  }
}

final memoryFactsProvider = NotifierProvider<MemoryFactsNotifier, List<MemoryFact>>(
  MemoryFactsNotifier.new,
);

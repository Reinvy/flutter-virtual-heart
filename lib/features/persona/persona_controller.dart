// Fitur Persona (FR-03, FR-10) — controller & provider persona.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:virtual_heart/services/database/objectbox_provider.dart';
import '../../models/persona_config.dart';

/// Mengelola [PersonaConfig] tunggal (aplikasi single-persona).
///
/// - [save] menyimpan (membuat baru ATAU memutasi in-place — TIDAK menghapus
///   box, memperbaiki bug lama yang selalu wipe saat edit).
/// - [reset] menghapus persona sepenuhnya.
class PersonaNotifier extends Notifier<PersonaConfig?> {
  @override
  PersonaConfig? build() {
    final db = ref.read(objectBoxServiceProvider);
    final personas = db.personaBox.getAll()..sort((a, b) => a.id.compareTo(b.id));
    if (personas.isEmpty) return null;
    if (personas.length > 1) {
      db.personaBox.removeMany(personas.skip(1).map((row) => row.id).toList());
    }
    return personas.first;
  }

  /// Menyimpan [persona]. Jika sudah ada record, pertahankan [id] agar
  /// ObjectBox meng-update, bukan menambah duplikat.
  void save(PersonaConfig persona) {
    final db = ref.read(objectBoxServiceProvider);
    final existing = db.personaBox.getAll()..sort((a, b) => a.id.compareTo(b.id));
    if (existing.isNotEmpty && persona.id == 0) {
      persona.id = existing.first.id;
      persona.createdAt = existing.first.createdAt;
    }
    db.personaBox.put(persona);
    state = persona;
  }

  /// Menghapus semua persona.
  void reset() {
    ref.read(objectBoxServiceProvider).personaBox.removeAll();
    state = null;
  }

  // Edit menyimpan instance baru dengan `id` yang sama: tanpa ini Riverpod
  // membandingkan field `record` (tidak ada) sehingga listener bisa terlewat.
  @override
  bool updateShouldNotify(PersonaConfig? previous, PersonaConfig? next) => true;
}

final personaProvider = NotifierProvider<PersonaNotifier, PersonaConfig?>(
  PersonaNotifier.new,
);

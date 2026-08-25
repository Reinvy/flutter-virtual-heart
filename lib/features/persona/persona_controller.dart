// Fitur Persona (FR-03, FR-10) — controller & provider persona.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/objectbox_provider.dart';
import '../../models/persona_config.dart';
import 'avatar_catalog.dart';

/// Mengelola [PersonaConfig] tunggal (aplikasi single-persona).
///
/// - [save] menyimpan (membuat baru ATAU memutasi in-place — TIDAK menghapus
///   box, memperbaiki bug lama yang selalu wipe saat edit).
/// - [reset] menghapus persona sepenuhnya.
class PersonaNotifier extends Notifier<PersonaConfig?> {
  @override
  PersonaConfig? build() {
    final db = ref.read(objectBoxServiceProvider);
    final personas = db.personaBox.getAll();
    return personas.isNotEmpty ? personas.first : null;
  }

  /// Menyimpan [persona]. Jika sudah ada record, pertahankan [id] agar
  /// ObjectBox meng-update, bukan menambah duplikat.
  void save(PersonaConfig persona) {
    final db = ref.read(objectBoxServiceProvider);
    final existing = db.personaBox.getAll();
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
}

final personaProvider = NotifierProvider<PersonaNotifier, PersonaConfig?>(
  PersonaNotifier.new,
);

/// Nama persona (fallback 'VirtualHeart').
final personaNameProvider = Provider<String>((ref) {
  final persona = ref.watch(personaProvider);
  return (persona?.name.isNotEmpty ?? false) ? persona!.name : 'VirtualHeart';
});

/// Opsi avatar aktif berdasarkan gender persona.
final personaAvatarProvider = Provider<AvatarOpt>((ref) {
  final persona = ref.watch(personaProvider);
  final isGirlfriend = persona?.gender == PersonaGender.girlfriend;
  return avatarOptFor(persona?.avatarId, isGirlfriend: isGirlfriend);
});

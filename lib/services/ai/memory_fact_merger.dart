// Merge fakta memori (FR-11) — murni, tanpa ObjectBox.
//
// Memisahkan logika penggabungan dari `ChatNotifier` agar bisa diuji tanpa
// database dan agar penulisan ulang ObjectBox di satu tempat saja.
import '../../models/memory_fact.dart';

/// Batas panjang field yang disimpan.
const int maxMemoryKeyChars = 80;
const int maxMemoryValueChars = 300;
const int maxMemorySnippetChars = 500;

/// Batas jumlah fakta yang disimpan.
const int maxMemoryFactsStored = 50;

/// Hasil penggabungan: baris yang harus di-`put` dan id yang harus dihapus.
class MemoryMergeResult {
  final List<MemoryFact> upserts;
  final List<int> deleteIds;

  const MemoryMergeResult({required this.upserts, required this.deleteIds});
}

/// Menggabungkan [incoming] ke [existing].
///
/// - Key dinormalisasi (huruf kecil) untuk pencocokan, nilai lama ditimpa.
/// - Duplikat di dalam [incoming] menghasilkan satu `upsert` saja.
/// - Setelah upsert, fakta tertua (paling lama tidak dirujuk) dihapus agar
///   total tidak melebihi [maxFacts].
MemoryMergeResult mergeFacts({
  required List<MemoryFact> existing,
  required List<MemoryFact> incoming,
  required String sourceSnippet,
  int maxFacts = maxMemoryFactsStored,
}) {
  final byKey = <String, MemoryFact>{};
  for (final fact in existing) {
    final key = _normalize(fact.key);
    if (key.isEmpty) continue;
    byKey.putIfAbsent(key, () => fact);
  }

  final upserts = <MemoryFact>[];
  final touched = <String>{};
  final snippet = _cap(sourceSnippet.trim(), maxMemorySnippetChars);

  for (final fact in incoming) {
    final key = _cap(fact.key.trim(), maxMemoryKeyChars);
    final value = _cap(fact.value.trim(), maxMemoryValueChars);
    if (key.isEmpty || value.isEmpty) continue;

    final normalized = _normalize(key);
    final match = byKey[normalized];
    if (match != null) {
      match
        ..key = key
        ..value = value
        ..category = fact.category
        ..sourceSnippet = snippet;
      if (touched.add(normalized)) upserts.add(match);
    } else {
      final created = MemoryFact(
        key: key,
        value: value,
        category: fact.category,
        sourceSnippet: snippet,
      );
      byKey[normalized] = created;
      touched.add(normalized);
      upserts.add(created);
    }
  }

  final deleteIds = <int>[];
  final all = byKey.values.toList();
  if (all.length > maxFacts) {
    all.sort((a, b) {
      final byReference = a.lastReferencedAt.compareTo(b.lastReferencedAt);
      if (byReference != 0) return byReference;
      return a.createdAt.compareTo(b.createdAt);
    });
    final excess = all.length - maxFacts;
    for (var i = 0; i < excess; i++) {
      final fact = all[i];
      if (fact.id != 0) {
        deleteIds.add(fact.id);
      } else {
        upserts.remove(fact);
      }
    }
  }

  return MemoryMergeResult(upserts: upserts, deleteIds: deleteIds);
}

String _normalize(String value) => value.trim().toLowerCase();

String _cap(String value, int max) {
  if (value.length <= max) return value;
  var cut = max;
  final last = value.codeUnitAt(cut - 1);
  if (last >= 0xD800 && last <= 0xDBFF && cut < value.length) cut -= 1;
  return value.substring(0, cut);
}

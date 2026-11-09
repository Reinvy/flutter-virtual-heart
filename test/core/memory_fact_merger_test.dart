// Unit test — mergeFacts (FR-11) tanpa ObjectBox.
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/models/memory_fact.dart';
import 'package:virtual_heart/services/ai/memory_fact_merger.dart';

void main() {
  group('mergeFacts', () {
    test('key sama (beda kapital) menimpa baris lama, bukan menduplikasi', () {
      final existing = [MemoryFact(key: 'Warna Favorit', value: 'biru')];
      final incoming = [
        MemoryFact(key: 'warna favorit', value: 'hijau', category: MemoryCategory.preference),
      ];

      final result = mergeFacts(existing: existing, incoming: incoming, sourceSnippet: 'halo');

      expect(result.upserts, hasLength(1));
      expect(result.upserts.single.value, 'hijau');
      expect(result.upserts.single.category, MemoryCategory.preference);
      expect(result.upserts.single.sourceSnippet, 'halo');
      expect(result.deleteIds, isEmpty);
    });

    test('duplikat di dalam satu batch menghasilkan satu upsert', () {
      final incoming = [
        MemoryFact(key: 'makanan', value: 'sushi'),
        MemoryFact(key: 'MAKANAN', value: 'ramen'),
      ];

      final result = mergeFacts(existing: const [], incoming: incoming, sourceSnippet: 'x');

      expect(result.upserts, hasLength(1));
      expect(result.upserts.single.value, 'ramen');
    });

    test('key/value kosong dilewati', () {
      final incoming = [
        MemoryFact(key: '  ', value: 'nilai'),
        MemoryFact(key: 'nama', value: '   '),
        MemoryFact(key: 'kota', value: 'Bandung'),
      ];

      final result = mergeFacts(existing: const [], incoming: incoming, sourceSnippet: 'x');

      expect(result.upserts, hasLength(1));
      expect(result.upserts.single.key, 'kota');
    });

    test('panjang key, value, dan snippet dibatasi', () {
      final incoming = [MemoryFact(key: 'k' * 500, value: 'v' * 900)];

      final result = mergeFacts(
        existing: const [],
        incoming: incoming,
        sourceSnippet: 's' * 900,
      );

      final fact = result.upserts.single;
      expect(fact.key.length, maxMemoryKeyChars);
      expect(fact.value.length, maxMemoryValueChars);
      expect(fact.sourceSnippet!.length, maxMemorySnippetChars);
    });

    test('fakta tertua dihapus saat melewati maxFacts', () {
      final now = DateTime(2026, 1, 1);
      final existing = [
        for (var i = 0; i < 3; i++)
          MemoryFact(
            id: i + 1,
            key: 'k$i',
            value: 'v$i',
            lastReferencedAt: now.add(Duration(days: i)),
            createdAt: now.add(Duration(days: i)),
          ),
      ];

      final result = mergeFacts(
        existing: existing,
        incoming: [MemoryFact(key: 'baru', value: 'nilai')],
        sourceSnippet: 'x',
        maxFacts: 3,
      );

      // k0 paling lama tidak dirujuk → dihapus.
      expect(result.deleteIds, [1]);
      expect(result.upserts.any((f) => f.key == 'baru'), isTrue);
    });
  });
}

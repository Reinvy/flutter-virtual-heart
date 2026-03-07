import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/memory_fact.dart';

/// Extracts [MemoryFact] items from a raw conversation snippet by sending a
/// dedicated extraction prompt to the on-device model.
///
/// The class is stateless; the caller supplies an inference function so that
/// [MemoryExtractor] has no direct dependency on [ModelServiceNotifier].
/// This keeps it independently testable.
///
/// Usage:
/// ```dart
/// final extractor = ref.read(memoryExtractorProvider);
/// final facts = await extractor.extractFacts(
///   conversation,
///   (p) => ref.read(modelServiceProvider.notifier).generateResponse(p),
/// );
/// ```
class MemoryExtractor {
  const MemoryExtractor();

  // Expected output line format: "FAKTA: <category> | <key> | <value>"
  static const String _prompt = '''
Baca percakapan berikut dan ekstrak HANYA fakta-fakta penting tentang User.
Format SETIAP fakta dalam satu baris:
FAKTA: <kategori> | <kunci> | <nilai>

Kategori yang valid: personal, event, preference, date
Contoh:
FAKTA: personal | nama | Budi
FAKTA: preference | makanan favorit | soto ayam
FAKTA: event | ulang tahun | 15 Januari

Percakapan:
{conversation}

Fakta-fakta (tulis HANYA baris FAKTA:, tanpa teks lain):''';

  /// Sends [conversation] to the model via [generateFn] and parses the
  /// structured output into [MemoryFact] objects.
  ///
  /// Returns an empty list when no facts are found or if inference fails.
  Future<List<MemoryFact>> extractFacts(
    String conversation,
    Future<String> Function(String prompt) generateFn,
  ) async {
    if (conversation.trim().isEmpty) return const [];

    final prompt = _prompt.replaceFirst('{conversation}', conversation);

    try {
      final raw = await generateFn(prompt);
      return _parse(raw);
    } catch (_) {
      return const [];
    }
  }

  List<MemoryFact> _parse(String raw) {
    final facts = <MemoryFact>[];

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('FAKTA:')) continue;

      final parts = trimmed.substring(6).split('|');
      if (parts.length < 3) continue;

      final categoryRaw = parts[0].trim().toLowerCase();
      final key = parts[1].trim();
      final value = parts.sublist(2).join('|').trim();

      if (key.isEmpty || value.isEmpty) continue;

      facts.add(MemoryFact(category: _parseCategory(categoryRaw), key: key, value: value));
    }

    return facts;
  }

  MemoryCategory _parseCategory(String raw) {
    switch (raw) {
      case 'event':
        return MemoryCategory.event;
      case 'preference':
        return MemoryCategory.preference;
      case 'date':
        return MemoryCategory.date;
      default:
        return MemoryCategory.personal;
    }
  }
}

final memoryExtractorProvider = Provider<MemoryExtractor>((_) => const MemoryExtractor());

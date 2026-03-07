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

  // Expected output line format: "FACT: <category> | <key> | <value>"
  static const String _prompt = '''
Read the following conversation and extract ONLY important facts about the User.
Format EACH fact on a single line:
FACT: <category> | <key> | <value>

Valid categories: personal, event, preference, date
Examples:
FACT: personal | name | John
FACT: preference | favorite food | chicken soup
FACT: event | birthday | January 15

Conversation:
{conversation}

Facts (write ONLY FACT: lines, no other text):''';

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
      if (!trimmed.startsWith('FACT:')) continue;

      final parts = trimmed.substring(5).split('|');
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

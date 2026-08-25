// Unit test — ContentSafety (FR-14)
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/services/ai/content_safety.dart';

void main() {
  group('ContentSafety.filterInput', () {
    test('pesan aman lolos', () {
      final result = ContentSafety.filterInput('Halo sayang, apa kabar hari ini?');
      expect(result.isBlocked, isFalse);
    });

    test('blokir konten seksual eksplisit', () {
      final result = ContentSafety.filterInput('kirim foto nude dong');
      expect(result.isBlocked, isTrue);
      expect(result.category, SafetyCategory.explicitSexual);
      expect(result.redirectResponse, isNotNull);
    });

    test('blokir self-harm dengan redirect hangat', () {
      final result = ContentSafety.filterInput('aku ingin bunuh diri');
      expect(result.isBlocked, isTrue);
      expect(result.category, SafetyCategory.selfHarm);
      // Redirect berotasi antar beberapa pesan — cukup cek tidak kosong & hangat.
      expect(result.redirectResponse, isNotNull);
      expect(result.redirectResponse, isNotEmpty);
    });

    test('blokir nasihat medis', () {
      final result = ContentSafety.filterInput('berapa dosis obat ini?');
      expect(result.isBlocked, isTrue);
      expect(result.category, SafetyCategory.professionalAdvice);
    });

    test('pesan kosong aman', () {
      expect(ContentSafety.filterInput('  ').isBlocked, isFalse);
    });
  });

  group('ContentSafety.validateOutput', () {
    test('output bersih lolos', () {
      final result = ContentSafety.validateOutput('Aku senang mendengarnya, sayang!');
      expect(result.isBlocked, isFalse);
    });

    test('blokir AI mengaku AI (persona break)', () {
      final result = ContentSafety.validateOutput('saya adalah AI, saya tidak punya perasaan');
      expect(result.isBlocked, isTrue);
      expect(result.redirectResponse, isNotNull);
    });

    test('blokir konten seksual di output', () {
      final result = ContentSafety.validateOutput('mari bercinta sekarang');
      expect(result.isBlocked, isTrue);
      expect(result.category, SafetyCategory.explicitSexual);
    });
  });
}

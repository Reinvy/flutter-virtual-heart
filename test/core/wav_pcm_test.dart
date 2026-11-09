// Unit test — parser WAV → PCM (FR-06).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/utils/wav_pcm.dart';

/// Membuat byte RIFF header + chunk list.
Uint8List _wav(List<_Chunk> chunks) {
  final body = BytesBuilder();
  for (final chunk in chunks) {
    body.add(chunk.id.codeUnits);
    final size = ByteData(4)..setUint32(0, chunk.data.length, Endian.little);
    body.add(size.buffer.asUint8List());
    body.add(chunk.data);
    // Padding wajib bila ukuran chunk ganjil.
    if (chunk.data.length.isOdd) body.addByte(0);
  }

  final payload = body.takeBytes();
  final header = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add((ByteData(4)..setUint32(0, payload.length + 4, Endian.little)).buffer.asUint8List())
    ..add('WAVE'.codeUnits);
  return Uint8List.fromList([...header.takeBytes(), ...payload]);
}

class _Chunk {
  const _Chunk(this.id, this.data);
  final String id;
  final List<int> data;
}

void main() {
  group('pcmFromWav', () {
    test('membaca chunk data meski ada LIST sebelum data', () {
      final wav = _wav(const [
        _Chunk('LIST', [1, 2, 3, 4, 5, 6]), // 6 byte (genap)
        _Chunk('data', [10, 20, 30, 40]),
      ]);

      expect(pcmFromWav(wav), [10, 20, 30, 40]);
    });

    test('melewati chunk berukuran ganjil beserta padding-nya', () {
      final wav = _wav(const [
        _Chunk('JUNK', [9, 9, 9]), // 3 byte → 1 byte padding
        _Chunk('data', [7, 8]),
      ]);

      expect(pcmFromWav(wav), [7, 8]);
    });

    test('menangani header WAV standar 44 byte', () {
      final wav = _wav([
        _Chunk('fmt ', List.filled(16, 0)),
        _Chunk('data', [1, 2, 3]),
      ]);

      expect(pcmFromWav(wav).length, 3);
    });

    test('melempar FormatException bila tidak ada chunk data', () {
      final wav = _wav([_Chunk('fmt ', List.filled(16, 0))]);

      expect(() => pcmFromWav(wav), throwsFormatException);
    });

    test('melempar FormatException bila bukan WAV', () {
      final notWav = Uint8List.fromList(List.filled(64, 65));

      expect(() => pcmFromWav(notWav), throwsFormatException);
    });
  });
}

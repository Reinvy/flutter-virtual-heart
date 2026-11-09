// Parser WAV → PCM mentah.
//
// Rekaman `record` menghasilkan file WAV; engine STT on-device hanya menerima
// PCM 16-bit little-endian tanpa header. Header WAV tidak selalu 44 byte
// (chunk `LIST`/`JUNK` bisa muncul sebelum `data`), jadi chunk dibaca berurutan
// alih-alih memotong 44 byte pertama.
import 'dart:math' as math;
import 'dart:typed_data';

/// Mengembalikan payload chunk `data` dari [wav].
///
/// Melempar [FormatException] bila file bukan WAV (RIFF/WAVE) atau tidak punya
/// chunk `data`.
Uint8List pcmFromWav(Uint8List wav) {
  if (wav.length < 12) {
    throw const FormatException('WAV terlalu pendek');
  }
  if (_fourCC(wav, 0) != 'RIFF' || _fourCC(wav, 8) != 'WAVE') {
    throw const FormatException('Bukan file WAV');
  }

  var offset = 12;
  final view = ByteData.sublistView(wav);

  while (offset + 8 <= wav.length) {
    final id = _fourCC(wav, offset);
    final size = view.getUint32(offset + 4, Endian.little);
    final dataStart = offset + 8;

    if (id == 'data') {
      if (dataStart > wav.length) break;
      final end = math.min(dataStart + size, wav.length);
      return Uint8List.sublistView(wav, dataStart, end);
    }

    // Chunk berukuran ganjil diikuti satu byte padding.
    offset = dataStart + size + (size.isOdd ? 1 : 0);
  }

  throw const FormatException('Chunk "data" WAV tidak ditemukan');
}

String _fourCC(Uint8List bytes, int offset) =>
    String.fromCharCodes(bytes, offset, offset + 4);

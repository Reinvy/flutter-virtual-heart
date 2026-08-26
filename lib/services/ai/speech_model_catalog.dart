// Katalog model speech on-device (STT/TTS via flutter_gemma_speech).
import 'package:flutter_gemma/flutter_gemma.dart' as gemma;

/// Opsi model speech (TTS atau STT) yang bisa diunduh pengguna.
class SpeechModelOption {
  final String id; // 'inflect' | 'matcha' | 'qwen3' | 'moonshine'
  final String name;
  final String description;
  final String sizeLabel;
  final bool isTts;
  final String? baseUrl; // TTS: fromNetwork(baseUrl); STT: model + tokenizer terpisah

  const SpeechModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeLabel,
    required this.isTts,
    this.baseUrl,
  });

  /// `TtsModelType` flutter_gemma yang sesuai (hanya untuk isTts).
  gemma.TtsModelType? get gemmaTtsType => switch (id) {
    'inflect' => gemma.TtsModelType.inflect,
    'matcha' => gemma.TtsModelType.matcha,
    'qwen3' => gemma.TtsModelType.qwen3,
    _ => null,
  };

  /// `SttModelType` flutter_gemma yang sesuai (hanya untuk !isTts).
  gemma.SttModelType? get gemmaSttType =>
      id == 'moonshine' ? gemma.SttModelType.moonshine : null;
}

/// Katalog model TTS (on-device, flutter_gemma_speech).
const kTtsModelOptions = <SpeechModelOption>[
  SpeechModelOption(
    id: 'inflect',
    name: 'Inflect-Nano-v2',
    description: 'Ringan & sangat cepat (EN). Default.',
    sizeLabel: '8 MB',
    isTts: true,
    baseUrl:
        'https://huggingface.co/sasha-denisov/inflect-nano-v2-litert/resolve/main/',
  ),
  SpeechModelOption(
    id: 'matcha',
    name: 'Matcha-TTS',
    description: 'Suara lebih natural (22050 Hz).',
    sizeLabel: '~100 MB',
    isTts: true,
    baseUrl: 'https://huggingface.co/litert-community/Matcha-TTS/resolve/main/',
  ),
  SpeechModelOption(
    id: 'qwen3',
    name: 'Qwen3-TTS',
    description: 'Multilingual (11 bahasa) — butuh ~6 GB RAM.',
    sizeLabel: '1.9 GB',
    isTts: true,
    baseUrl:
        'https://huggingface.co/litert-community/Qwen3-TTS-12Hz-0.6B-Base/resolve/main/',
  ),
];

/// Katalog model STT (on-device, flutter_gemma_speech).
const kSttModelOptions = <SpeechModelOption>[
  SpeechModelOption(
    id: 'moonshine',
    name: 'Moonshine-Tiny',
    description: 'Transkripsi on-device (raw PCM 16 kHz).',
    sizeLabel: '75 MB',
    isTts: false,
  ),
];

/// Cari opsi TTS berdasarkan id; fallback ke Inflect.
SpeechModelOption ttsModelById(String? id) {
  for (final opt in kTtsModelOptions) {
    if (opt.id == id) return opt;
  }
  return kTtsModelOptions.first;
}

/// Cari opsi STT berdasarkan id; fallback ke moonshine.
SpeechModelOption sttModelById(String? id) {
  for (final opt in kSttModelOptions) {
    if (opt.id == id) return opt;
  }
  return kSttModelOptions.first;
}

/// URL model & tokenizer STT moonshine.
const kSttModelUrl =
    'https://huggingface.co/litert-community/moonshine-tiny/resolve/main/'
    'moonshine_tiny_5s_f32.tflite';
const kSttTokenizerUrl =
    'https://huggingface.co/UsefulSensors/moonshine/resolve/main/'
    'ctranslate2/tiny/tokenizer.json';

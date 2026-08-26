// Katalog model LLM on-device (FR-04) — sumber kebenaran pilihan model.
//
// Model di-download dari HuggingFace (litert-community) atau di-upload dari
// penyimpanan lokal. `fileType` menentukan engine: 'litertlm' → LiteRT-LM
// (mendukung speech), 'task' → MediaPipe (mobile, tanpa speech).
import 'package:flutter_gemma/flutter_gemma.dart' as gemma;

/// Opsi model yang bisa dipilih pengguna.
class ModelOption {
  final String id;
  final String name;
  final String description;
  final String fileName;
  final String url;
  final String fileType; // 'litertlm' | 'task'
  final String modelType; // 'qwen' | 'smollm' | 'deepseek' | 'gemmaIt'
  final String sizeLabel;
  final bool gated; // butuh HuggingFace token

  const ModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.fileName,
    required this.url,
    required this.fileType,
    required this.modelType,
    required this.sizeLabel,
    this.gated = false,
  });

  /// `ModelType` flutter_gemma yang sesuai.
  gemma.ModelType get gemmaModelType => switch (modelType) {
    'qwen' => gemma.ModelType.qwen,
    'smollm' => gemma.ModelType.general,
    'deepseek' => gemma.ModelType.deepSeek,
    'gemmaIt' => gemma.ModelType.gemmaIt,
    _ => gemma.ModelType.qwen,
  };

  /// `ModelFileType` flutter_gemma yang sesuai.
  gemma.ModelFileType get gemmaFileType =>
      fileType == 'litertlm' ? gemma.ModelFileType.litertlm : gemma.ModelFileType.task;

  bool get isLiteRtl => fileType == 'litertlm';
}

/// Katalog default. Model pertama = default (Qwen 2.5 1.5B, .litertlm).
const kModelOptions = <ModelOption>[
  ModelOption(
    id: 'qwen2.5-1.5b',
    name: 'Qwen 2.5 1.5B',
    description: 'Multibahasa, kuat & seimbang — default VirtualHeart.',
    fileName: 'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/'
        'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm',
    fileType: 'litertlm',
    modelType: 'qwen',
    sizeLabel: '1.6 GB',
  ),
  ModelOption(
    id: 'qwen2.5-0.5b',
    name: 'Qwen 2.5 0.5B',
    description: 'Ringan & cepat — cocok perangkat RAM rendah.',
    fileName: 'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv4096.task',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/'
        'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv4096.task',
    fileType: 'task',
    modelType: 'qwen',
    sizeLabel: '0.5 GB',
  ),
  ModelOption(
    id: 'smollm-135m',
    name: 'SmolLM 135M',
    description: 'Ultra-ringan (135 MB) — untuk perangkat sangat terbatas.',
    fileName: 'SmolLM-135M-Instruct-q8_ekv2048.task',
    url:
        'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/'
        'SmolLM-135M-Instruct-q8_ekv2048.task',
    fileType: 'task',
    modelType: 'smollm',
    sizeLabel: '135 MB',
  ),
  ModelOption(
    id: 'deepseek-r1-1.5b',
    name: 'DeepSeek R1 1.5B',
    description: 'Penalaran mendalam — untuk percakapan yang reflektif.',
    fileName: 'DeepSeek-R1-Distill-Qwen-1.5B-q8_ekv4096.task',
    url:
        'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/'
        'DeepSeek-R1-Distill-Qwen-1.5B-q8_ekv4096.task',
    fileType: 'task',
    modelType: 'deepseek',
    sizeLabel: '1.7 GB',
  ),
  ModelOption(
    id: 'gemma3-1b',
    name: 'Gemma 3 1B',
    description: 'Google Gemma — butuh akses & token HuggingFace (gated).',
    fileName: 'Gemma3-1B-IT-multi-prefill-seq-q4_ekv4096.litertlm',
    url:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/'
        'Gemma3-1B-IT-multi-prefill-seq-q4_ekv4096.litertlm',
    fileType: 'litertlm',
    modelType: 'gemmaIt',
    sizeLabel: '0.5 GB',
    gated: true,
  ),
];

/// Model default bila pengguna langsung lanjut tanpa memilih.
ModelOption get kDefaultModelOption => kModelOptions.first;

/// Cari opsi berdasarkan id; fallback ke default.
ModelOption modelOptionById(String? id) {
  for (final opt in kModelOptions) {
    if (opt.id == id) return opt;
  }
  return kDefaultModelOption;
}

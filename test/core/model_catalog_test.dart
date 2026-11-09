// Unit test — katalog model & speech (FR-04).
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/services/ai/model_catalog.dart';
import 'package:virtual_heart/services/ai/speech_model_catalog.dart';

void main() {
  group('katalog model', () {
    test('default adalah Qwen 2.5 1.5B .litertlm', () {
      expect(kDefaultModelOption.id, 'qwen2.5-1.5b');
      expect(kDefaultModelOption.fileType, 'litertlm');
      expect(kDefaultModelOption.fileName, endsWith('.litertlm'));
    });

    test('modelOptionByFileName menemukan setiap entri katalog', () {
      for (final opt in kModelOptions) {
        expect(modelOptionByFileName(opt.fileName).id, opt.id);
      }
    });

    test('modelOptionByFileName tidak peka huruf besar/kecil & spasi', () {
      final file = kModelOptions.first.fileName;
      expect(modelOptionByFileName('  ${file.toUpperCase()} ').id, 'qwen2.5-1.5b');
    });

    test('nama file tak dikenal → model default', () {
      expect(modelOptionByFileName('model-kustom-saya.litertlm').id, 'qwen2.5-1.5b');
      expect(modelOptionByFileName(null).id, 'qwen2.5-1.5b');
      expect(modelOptionByFileName('   ').id, 'qwen2.5-1.5b');
    });

    test('pemetaan tipe model & file ke API flutter_edge_ai', () {
      expect(modelOptionByFileName('SmolLM-135M-Instruct-q8_ekv2048.task').modelType, 'smollm');
      expect(
        modelOptionByFileName('SmolLM-135M-Instruct-q8_ekv2048.task').edgeAiFileType.name,
        'task',
      );
      expect(
        modelOptionByFileName('Gemma3-1B-IT-multi-prefill-seq-q4_ekv4096.litertlm')
            .edgeAiModelType
            .name,
        'gemmaIt',
      );
      expect(
        modelOptionByFileName('Gemma3-1B-IT-multi-prefill-seq-q4_ekv4096.litertlm')
            .edgeAiFileType
            .name,
        'litertlm',
      );
      expect(kDefaultModelOption.edgeAiModelType.name, 'qwen');
    });
  });

  group('katalog speech', () {
    test('TTS default Inflect dengan tipe edge_ai', () {
      expect(ttsModelById(null).id, 'inflect');
      expect(ttsModelById('matcha').edgeAiTtsType!.name, 'matcha');
      expect(ttsModelById('qwen3').edgeAiTtsType!.name, 'qwen3');
      expect(ttsModelById('inflect').edgeAiTtsType!.name, 'inflect');
      expect(ttsModelById('tidak-ada').id, 'inflect');
    });

    test('STT default moonshine', () {
      expect(sttModelById(null).id, 'moonshine');
      expect(sttModelById('moonshine').edgeAiSttType!.name, 'moonshine');
      expect(sttModelById('moonshine').edgeAiTtsType, isNull);
      expect(ttsModelById('inflect').edgeAiSttType, isNull);
    });
  });
}

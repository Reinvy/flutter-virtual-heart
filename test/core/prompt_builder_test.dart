// Unit test — PromptBuilder (FR-05, FR-13)
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/models/memory_fact.dart';
import 'package:virtual_heart/models/message.dart';
import 'package:virtual_heart/models/mood_state.dart';
import 'package:virtual_heart/models/persona_config.dart';
import 'package:virtual_heart/services/ai/prompt_builder.dart';

void main() {
  group('PromptBuilder.buildSystemPrompt', () {
    test('menyertakan nama, gender, kepribadian, dan mood', () {
      final persona = PersonaConfig(
        name: 'Luna',
        nicknameForUser: 'Babe',
        gender: PersonaGender.girlfriend,
        personalityPreset: PersonalityPreset.cheerful,
        hobbies: const ['Music', 'Cooking'],
      );
      final mood = MoodState(current: MoodType.happy, intensity: 0.8);

      final prompt = PromptBuilder.buildSystemPrompt(persona, mood, const [], '');

      expect(prompt, contains('Your name is Luna'));
      expect(prompt, contains('female'));
      expect(prompt, contains('Babe'));
      expect(prompt, contains('Cheerful'));
      expect(prompt, contains('happy'));
      expect(prompt, contains('80%'));
      expect(prompt, contains('Hobbies: Music, Cooking'));
    });

    test('menyertakan fakta memori dan ringkasan bila ada', () {
      final persona = PersonaConfig(name: 'Arya', nicknameForUser: 'Dear');
      final mood = MoodState();
      final facts = [
        MemoryFact(key: 'warna favorit', value: 'biru', category: MemoryCategory.preference),
      ];

      final prompt = PromptBuilder.buildSystemPrompt(persona, mood, facts, 'Ringkasan: suka kopi.');

      expect(prompt, contains('warna favorit: biru'));
      expect(prompt, contains('[CONTEXT SUMMARY]'));
      expect(prompt, contains('Ringkasan: suka kopi.'));
    });
  });

  group('PromptBuilder.buildFullPrompt', () {
    test('memuat riwayat dan pesan user terakhir', () {
      final history = [
        Message(role: MessageRole.user, content: 'Halo'),
        Message(role: MessageRole.assistant, content: 'Hai!'),
      ];
      final prompt = PromptBuilder.buildFullPrompt('[SYSTEM]', history, 'Apa kabar?');

      expect(prompt, contains('[SYSTEM]'));
      expect(prompt, contains('[User]'));
      expect(prompt, contains('Halo'));
      expect(prompt, contains('[Assistant]'));
      expect(prompt, contains('Hai!'));
      expect(prompt, endsWith('Apa kabar?'));
    });

    test('membatasi riwayat ke maxRecentMessages', () {
      final history = List.generate(
        PromptBuilder.maxRecentMessages + 10,
        (i) => Message(role: MessageRole.user, content: 'msg$i'),
      );
      final prompt = PromptBuilder.buildFullPrompt('[SYSTEM]', history, 'terakhir');

      expect('msg0'.allMatches(prompt).length, 0); // yang paling lama terpotong
      expect(prompt, contains('msg${PromptBuilder.maxRecentMessages - 1}'));
    });
  });

  group('PromptBuilder.buildSummarizationPrompt', () {
    test('membatasi ke 60 pesan terakhir', () {
      final messages = List.generate(
        80,
        (i) => Message(role: i.isEven ? MessageRole.user : MessageRole.assistant, content: 'm$i'),
      );
      final prompt = PromptBuilder.buildSummarizationPrompt(messages);

      expect(prompt, isNot(contains('m0')));
      expect(prompt, contains('m79'));
      expect(prompt, startsWith('Write a brief summary'));
    });
  });
}

// Unit test — MoodService (FR-09) dengan fake MoodStore (tanpa ObjectBox).
import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';
import 'package:virtual_heart/models/mood_state.dart';
import 'package:virtual_heart/services/mood_service.dart';

/// Fake Box minimal untuk unit test (hanya getAll/put).
class _FakeMoodBox implements Box<MoodState> {
  final List<MoodState> _items = [];

  @override
  List<MoodState> getAll() => List.of(_items);

  @override
  int put(MoodState object, {PutMode mode = PutMode.put}) {
    final idx = _items.indexWhere((m) => m.id == object.id);
    if (idx >= 0) {
      _items[idx] = object;
    } else {
      if (object.id == 0) object.id = _items.length + 1;
      _items.add(object);
    }
    return object.id;
  }

  // Metode Box lain — tidak dipakai oleh MoodService, lempar saja.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMoodStore implements MoodStore {
  @override
  final moodStateBox = _FakeMoodBox();
}

void main() {
  group('MoodService', () {
    late _FakeMoodStore store;
    late MoodService service;

    setUp(() {
      store = _FakeMoodStore();
      service = MoodService(store);
    });

    test('getCurrentMood membuat mood default happy 0.7', () {
      final mood = service.getCurrentMood();
      expect(mood.current, MoodType.happy);
      expect(mood.intensity, 0.7);
    });

    test('updateMoodFromConversation: kata positif → happy', () {
      final mood = service.updateMoodFromConversation(
        'Aku senang sekali bersamamu, cinta! Kamu membuatku bahagia.',
      );
      expect(mood.current, MoodType.happy);
      expect(mood.intensity, greaterThanOrEqualTo(0.7));
    });

    test('updateMoodFromConversation: kata sedih → sad', () {
      final mood = service.updateMoodFromConversation(
        'Aku sedih dan merasa kesepian hari ini...',
      );
      expect(mood.current, MoodType.sad);
    });

    test('updateMoodFromConversation: kata playful → playful', () {
      final mood = service.updateMoodFromConversation('haha lucu sekali, kamu jahil!');
      expect(mood.current, MoodType.playful);
    });

    test('updateMoodFromIdleTime: idle ≥ 12 jam → longing 0.90', () {
      final mood = service.getCurrentMood();
      mood.lastInteractionAt = DateTime.now().subtract(const Duration(hours: 13));
      store.moodStateBox.put(mood);

      final updated = service.updateMoodFromIdleTime();
      expect(updated.current, MoodType.longing);
      expect(updated.intensity, 0.90);
    });

    test('updateMoodFromIdleTime: idle < 6 jam → tidak berubah', () {
      final mood = service.getCurrentMood();
      mood.lastInteractionAt = DateTime.now().subtract(const Duration(hours: 1));
      store.moodStateBox.put(mood);

      final updated = service.updateMoodFromIdleTime();
      expect(updated.current, MoodType.happy);
    });

    test('recordInteraction memperbarui lastInteractionAt', () {
      final mood = service.getCurrentMood();
      mood.lastInteractionAt = DateTime.now().subtract(const Duration(days: 1));
      store.moodStateBox.put(mood);

      service.recordInteraction();
      final after = service.getCurrentMood();
      expect(after.lastInteractionAt.difference(DateTime.now()).inSeconds.abs(), lessThan(60));
    });
  });
}

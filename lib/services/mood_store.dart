// Kontrak penyimpanan mood — dipisah agar `MoodService` tidak bergantung pada
// implementasi ObjectBox (dan agar test bisa memakai fake).
import 'package:objectbox/objectbox.dart';

import '../models/mood_state.dart';

abstract class MoodStore {
  Box<MoodState> get moodStateBox;
}

// TODO Phase 1.2: Add @Entity() ObjectBox annotation and run build_runner

enum MessageRole { user, assistant }

class Message {
  int id = 0;
  late MessageRole role;
  late String content;
  late DateTime timestamp;
  bool isVoice = false;
  String? mood;
}

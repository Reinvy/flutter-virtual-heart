// Entity ObjectBox — Pesan percakapan (FR-05)
import 'package:objectbox/objectbox.dart';

enum MessageRole { user, assistant }

@Entity()
class Message {
  @Id()
  int id = 0;

  String content = '';
  bool isVoice = false;
  String? mood;

  @Property(type: PropertyType.date)
  DateTime timestamp = DateTime.now();

  // Enum backing field (stored as int index)
  int roleIndex = 0;

  MessageRole get role => MessageRole.values[roleIndex];
  set role(MessageRole value) => roleIndex = value.index;

  Message({
    this.id = 0,
    MessageRole role = MessageRole.user,
    this.content = '',
    DateTime? timestamp,
    this.isVoice = false,
    this.mood,
  }) : timestamp = timestamp ?? DateTime.now() {
    roleIndex = role.index;
  }
}

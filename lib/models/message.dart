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

  /// `true` bila pesan ini diblokir content safety (FR-14).
  ///
  /// Pesan tetap disimpan agar pengguna melihat apa yang diketik, tetapi
  /// **tidak pernah** dimasukkan ke prompt, ringkasan, atau ekstraksi memori.
  bool isBlocked = false;

  @Property(type: PropertyType.date)
  DateTime timestamp = DateTime.now();

  // Enum backing field (stored as int index)
  int roleIndex = 0;

  MessageRole get role =>
      MessageRole.values[roleIndex.clamp(0, MessageRole.values.length - 1)];
  set role(MessageRole value) => roleIndex = value.index;

  Message({
    this.id = 0,
    MessageRole role = MessageRole.user,
    this.content = '',
    DateTime? timestamp,
    this.isVoice = false,
    this.mood,
    this.isBlocked = false,
  }) : timestamp = timestamp ?? DateTime.now() {
    roleIndex = role.index;
  }
}

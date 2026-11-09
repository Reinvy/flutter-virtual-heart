// Fitur Chat (FR-05) — state model chat.
import '../../models/message.dart';

/// Jenis kegagalan pipeline chat yang bisa ditampilkan ke pengguna.
///
/// Controller sengaja **tidak** menyimpan teks error: `ChatScreen` memetakan
/// nilai ini ke [AppStrings] agar tetap terlokalisasi.
enum ChatErrorKind {
  /// Model belum dimuat / engine tidak siap.
  modelUnavailable,

  /// Prompt melebihi context window model.
  contextLimit,

  /// Generasi gagal karena sebab lain.
  generationFailed,

  /// Pengguna menghentikan generasi.
  interrupted,
}

/// Kegagalan generasi yang sedang ditampilkan.
class ChatError {
  final ChatErrorKind kind;

  /// `true` bila percobaan ulang masuk akal untuk jenis ini.
  final bool canRetry;

  const ChatError(this.kind, {this.canRetry = false});
}

/// Urutan kronologis yang stabil: timestamp, lalu id (pesan yang dibuat pada
/// milidetik yang sama tidak boleh bertukar posisi antar-reload).
int compareMessages(Message a, Message b) {
  final byTime = a.timestamp.compareTo(b.timestamp);
  if (byTime != 0) return byTime;
  return a.id.compareTo(b.id);
}

/// State layar chat: daftar pesan + status streaming.
class ChatState {
  final List<Message> messages;
  final bool isTyping;

  /// Akumulasi token AI selama streaming.
  final String streamingBuffer;

  /// Kegagalan generasi terakhir yang belum ditutup pengguna.
  final ChatError? error;

  const ChatState({
    required this.messages,
    this.isTyping = false,
    this.streamingBuffer = '',
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isTyping,
    String? streamingBuffer,
    ChatError? error,
    bool clearError = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping,
    streamingBuffer: streamingBuffer ?? this.streamingBuffer,
    error: clearError ? null : (error ?? this.error),
  );
}

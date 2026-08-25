// Fitur Chat (FR-05) — state model chat.
import '../../models/message.dart';

/// State layar chat: daftar pesan + status streaming.
class ChatState {
  final List<Message> messages;
  final bool isTyping;

  /// Akumulasi token AI selama streaming.
  final String streamingBuffer;

  const ChatState({required this.messages, this.isTyping = false, this.streamingBuffer = ''});

  ChatState copyWith({List<Message>? messages, bool? isTyping, String? streamingBuffer}) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        streamingBuffer: streamingBuffer ?? this.streamingBuffer,
      );
}

import 'package:flutter/material.dart';

// TODO Phase 2.6: Implement ChatScreen (single room, no chatId)
// - AppBar: avatar + persona name + mood subtitle + settings button
// - Streaming AI responses token-by-token
// - Persist messages to ObjectBox
// - Trigger MemoryExtractor + MoodService after each AI response

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Chat — Phase 2.6')));
  }
}

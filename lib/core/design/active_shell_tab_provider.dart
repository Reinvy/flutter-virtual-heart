// State indeks tab shell navigasi aktif (0: Hub, 1: Chat, 2: Memory, 3: Settings).
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    if (state != index) state = index;
  }
}

final activeShellTabProvider = NotifierProvider<ActiveShellTabNotifier, int>(
  ActiveShellTabNotifier.new,
);

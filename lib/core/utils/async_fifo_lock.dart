// Mutex FIFO asinkron ringan untuk mengurutkan akses resource tunggal.
import 'dart:async';

/// Mengantrekan pemanggil secara FIFO tanpa saling menimpa completer.
class AsyncFifoLock {
  Future<void> _tail = Future<void>.value();

  /// Menunggu giliran dan mengembalikan fungsi `release` yang wajib dipanggil
  /// di blok `finally`.
  Future<void Function()> acquire() async {
    final previous = _tail;
    final mine = Completer<void>();
    _tail = mine.future;
    await previous;
    var released = false;
    return () {
      if (!released) {
        released = true;
        if (!mine.isCompleted) mine.complete();
      }
    };
  }

  /// Menjalankan [action] secara eksklusif sesuai urutan antrean.
  Future<T> run<T>(Future<T> Function() action) async {
    final release = await acquire();
    try {
      return await action();
    } finally {
      release();
    }
  }
}

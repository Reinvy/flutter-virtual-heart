// Unit test — AsyncFifoLock (antrean FIFO mutex untuk ModelServiceNotifier).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/utils/async_fifo_lock.dart';

void main() {
  group('AsyncFifoLock', () {
    test('mengeksekusi 3+ pemanggil bersamaan secara berurutan FIFO tanpa deadlock', () async {
      final lock = AsyncFifoLock();
      final order = <int>[];
      final firstGate = Completer<void>();

      final f1 = lock.run(() async {
        order.add(1);
        await firstGate.future;
        order.add(10);
      });
      final f2 = lock.run(() async {
        order.add(2);
      });
      final f3 = lock.run(() async {
        order.add(3);
      });

      await Future<void>.delayed(Duration.zero);
      expect(order, [1]);

      firstGate.complete();
      await Future.wait([f1, f2, f3]);
      expect(order, [1, 10, 2, 3]);
    });

    test('tetap melepas kunci saat aksi melempar error', () async {
      final lock = AsyncFifoLock();

      await expectLater(
        lock.run<void>(() async => throw StateError('boom')),
        throwsStateError,
      );

      final result = await lock.run(() async => 42);
      expect(result, 42);
    });
  });
}

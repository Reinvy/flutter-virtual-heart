// Unit test — perhitungan jadwal notifikasi (FR-18).
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:virtual_heart/services/notification_time.dart';

void main() {
  // Harus dijalankan sebelum `getLocation` dipanggil (termasuk saat deklarasi).
  tz_data.initializeTimeZones();

  group('nextInstanceOf', () {
    final jakarta = tz.getLocation('Asia/Jakarta');

    test('waktu hari ini bila belum lewat', () {
      final now = tz.TZDateTime(jakarta, 2026, 11, 9, 6, 30);
      final next = nextInstanceOf(8, 0, now);

      expect(next.year, 2026);
      expect(next.month, 11);
      expect(next.day, 9);
      expect(next.hour, 8);
      expect(next.minute, 0);
      expect(next.location, jakarta);
    });

    test('besok bila jam sudah lewat', () {
      final now = tz.TZDateTime(jakarta, 2026, 11, 9, 9, 15);
      final next = nextInstanceOf(8, 0, now);

      expect(next.day, 10);
      expect(next.hour, 8);
    });

    test('jam yang sama persis dijadwalkan besok (tidak "sekarang")', () {
      final now = tz.TZDateTime(jakarta, 2026, 11, 9, 8, 0);
      final next = nextInstanceOf(8, 0, now);

      expect(next.day, 10);
    });

    test('menyeberang akhir bulan dengan benar', () {
      final now = tz.TZDateTime(jakarta, 2026, 11, 30, 23, 30);
      final next = nextInstanceOf(7, 45, now);

      expect(next.month, 12);
      expect(next.day, 1);
      expect(next.hour, 7);
      expect(next.minute, 45);
    });
  });
}

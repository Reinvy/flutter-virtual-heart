// Helper waktu notifikasi — fungsi murni yang bisa dites tanpa plugin.
import 'package:timezone/timezone.dart' as tz;

/// Mengembalikan instance ([hour], [minute]) berikutnya: hari ini bila belum
/// lewat, selain itu besok.
///
/// [now] harus memakai lokasi yang sama dengan jadwal yang diinginkan
/// (`tz.local` di produksi). Perbandingan dilakukan pada waktu absolut, jadi
/// waktu yang tepat sama dianggap "sudah lewat" dan dijadwalkan besok.
tz.TZDateTime nextInstanceOf(int hour, int minute, tz.TZDateTime now) {
  final scheduled = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (scheduled.isAfter(now)) return scheduled;
  return tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + 1,
    hour,
    minute,
  );
}

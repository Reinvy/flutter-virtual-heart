// Helper waktu notifikasi — fungsi murni yang bisa dites tanpa plugin.
import 'package:material_ui/material_ui.dart' show TimeOfDay;
import 'package:timezone/timezone.dart' as tz;

/// Mengembalikan instance [time] berikutnya: hari ini bila belum lewat,
/// selain itu besok.
///
/// [now] harus memakai lokasi yang sama dengan jadwal yang diinginkan
/// (`tz.local` di produksi). Perbandingan dilakukan pada waktu absolut, jadi
/// tengah malam yang tepat dianggap "sudah lewat" dan dijadwalkan besok.
tz.TZDateTime nextInstanceOf(TimeOfDay time, tz.TZDateTime now) {
  final scheduled = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (scheduled.isAfter(now)) return scheduled;
  return tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + 1,
    time.hour,
    time.minute,
  );
}

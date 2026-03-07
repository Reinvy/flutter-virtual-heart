import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String formatDate(DateTime dt) => DateFormat('d MMMM yyyy').format(dt);

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(dt);
  }
}

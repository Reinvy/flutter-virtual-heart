// Utilitas format tanggal (docs/DESIGN.md §6 — core/utils)
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';

abstract final class DateFormatter {
  DateFormatter._();

  static String formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String formatDate(DateTime dt) => DateFormat('d MMMM yyyy').format(dt);

  /// Format relatif yang sadar bahasa. Default: Bahasa Indonesia.
  static String formatRelative(DateTime dt, [AppStrings? strings]) {
    final s = strings ?? const IndonesianStrings();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return s.timeJustNow;
    if (diff.inHours < 1) return s.timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return s.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return s.timeDaysAgo(diff.inDays);
    return formatDate(dt);
  }
}

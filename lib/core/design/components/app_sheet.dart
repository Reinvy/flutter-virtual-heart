// Komponen shared — pembungkus modal bottom sheet.
//
// Latar transparan + shape dari theme supaya sheet memakai permukaan & radius
// sistem. `showDragHandle` dimatikan di theme; sheet menggambar handle sendiri.
import 'package:material_ui/material_ui.dart';

/// Menampilkan modal bottom sheet dengan gaya Atelier.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => child,
  );
}

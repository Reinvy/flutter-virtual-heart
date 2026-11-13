// Komponen shared — penjaga tombol back agar aplikasi tidak tertutup pada satu kali tekan.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_strings.dart';

/// Mencegah penutupan aplikasi seketika saat tombol back ditekan di halaman akar.
///
/// Jika [canPop] bernilai `true`, navigasi kembali berjalan normal.
/// Jika `false`, [onBackBlocked] dipanggil lebih dulu; bila mengembalikan `true`
/// (misalnya berpindah ke tab awal atau mundur halaman onboarding), aksi dianggap
/// selesai. Jika tidak, tekan pertama menampilkan SnackBar konfirmasi dan
/// tekan kedua dalam rentang [exitWindow] memanggil [onExit] (default:
/// [SystemNavigator.pop]).
class DoubleBackExitScope extends ConsumerStatefulWidget {
  const DoubleBackExitScope({
    super.key,
    required this.child,
    this.canPop = false,
    this.onBackBlocked,
    this.onExit,
    this.exitWindow = const Duration(seconds: 2),
    this.now,
  });

  final Widget child;
  final bool canPop;
  final bool Function()? onBackBlocked;
  final Future<void> Function()? onExit;
  final Duration exitWindow;
  final DateTime Function()? now;

  @override
  ConsumerState<DoubleBackExitScope> createState() =>
      DoubleBackExitScopeState();
}

class DoubleBackExitScopeState extends ConsumerState<DoubleBackExitScope> {
  DateTime? _lastBackAt;
  bool _hasPrompted = false;

  DateTime _currentTime() => widget.now?.call() ?? DateTime.now();

  /// Mengatur ulang jendela konfirmasi keluar dan menyembunyikan SnackBar aktif.
  void reset() {
    _lastBackAt = null;
    if (_hasPrompted && mounted) {
      _hasPrompted = false;
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    } else {
      _hasPrompted = false;
    }
  }

  void _handlePopInvoked(bool didPop, Object? _) {
    if (didPop) return;

    if (widget.onBackBlocked?.call() ?? false) {
      reset();
      return;
    }

    final now = _currentTime();
    final previous = _lastBackAt;
    if (previous != null && now.difference(previous) <= widget.exitWindow) {
      reset();
      final exit = widget.onExit ?? SystemNavigator.pop;
      unawaited(exit());
      return;
    }

    _lastBackAt = now;
    _hasPrompted = true;
    final strings = ref.read(appStringsProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.exitBackAgainPrompt),
          duration: widget.exitWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canPop,
      onPopInvokedWithResult: _handlePopInvoked,
      child: widget.child,
    );
  }
}

// Design tokens — Motion (docs/DESIGN.md §2.6)
//
// Semua animasi dekoratif/loop wajib memeriksa
// `MediaQuery.disableAnimationsOf(context)` dan berhenti statis.
import 'package:material_ui/material_ui.dart';

abstract final class AppDurations {
  AppDurations._();

  /// Perubahan instan: warna border, opacity.
  static const Duration durationInstant = Duration(milliseconds: 90);

  /// Micro-interactions: hover, state toggle, chip.
  static const Duration durationFast = Duration(milliseconds: 140);

  /// Transisi antar layar, sheet.
  static const Duration durationNormal = Duration(milliseconds: 260);

  /// Elemen hero, onboarding.
  static const Duration durationSlow = Duration(milliseconds: 420);

  /// Siklus rotasi halus ResonanceMark.
  static const Duration durationOrbital = Duration(milliseconds: 3200);

  /// Jeda antar item pada animasi berurutan.
  static const Duration stagger = Duration(milliseconds: 60);

  /// Kurva standar untuk sebagian besar animasi.
  static const Curve curveStandard = Curves.easeOutCubic;

  /// Kurva emotive — transisi lembut dua arah.
  static const Curve curveEmotive = Curves.easeInOutCubic;

  /// Kurva pegas untuk state pop (badge, check).
  static const Curve curveSpring = Curves.easeOutBack;
}

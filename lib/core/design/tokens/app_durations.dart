// Design tokens — Motion (docs/DESIGN.md §2.6)
import 'package:flutter/material.dart';

abstract final class AppDurations {
  AppDurations._();

  /// Micro-interactions: hover, state toggle, chip.
  static const Duration durationFast = Duration(milliseconds: 120);

  /// Transisi antar layar, sheet.
  static const Duration durationNormal = Duration(milliseconds: 240);

  /// Elemen hero, onboarding.
  static const Duration durationSlow = Duration(milliseconds: 400);

  /// Kurva standar untuk sebagian besar animasi.
  static const Curve curveStandard = Curves.easeOutCubic;

  /// Kurva emotive — heartbeat, bounce lembut.
  static const Curve curveEmotive = Curves.easeInOutBack;
}

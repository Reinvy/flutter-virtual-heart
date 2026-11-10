// Unit test — kontras token warna (DESIGN §2, WCAG AA 4.5:1).
//
// Token eksplisit (`primaryDeep`, `textSecondary`, `accentDeep`, `goldText`)
// hanya aman di mode terang; varian `*Dark` wajib aman di mode gelap.
// Test ini menjaga invarian tersebut.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/design/app_theme.dart';
import 'package:virtual_heart/core/design/tokens/app_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('kontras token >= 4.5:1', () {
    final cases = <String, (Color, Color)>{
      'primaryDeep / background': (AppColors.primaryDeep, AppColors.background),
      'primaryDeepDark / backgroundDark': (
        AppColors.primaryDeepDark,
        AppColors.backgroundDark,
      ),
      'textSecondary / surface': (AppColors.textSecondary, AppColors.surface),
      'textSecondaryDark / surfaceDark': (
        AppColors.textSecondaryDark,
        AppColors.surfaceDark,
      ),
      'primaryDark / surfaceDark': (AppColors.primaryDark, AppColors.surfaceDark),
      'onSurfaceVariant / surface': (
        AppColors.textSecondary,
        AppColors.surface,
      ),
      'textOnPrimary / actionStart': (AppColors.textOnPrimary, AppColors.actionStart),
      'textOnPrimaryDark / actionStartDark': (
        AppColors.textOnPrimaryDark,
        AppColors.actionStartDark,
      ),
      'accentDeep / surface': (AppColors.accentDeep, AppColors.surface),
      'accentDeepDark / surfaceDark': (AppColors.accentDeepDark, AppColors.surfaceDark),
      'goldText / surface': (AppColors.goldText, AppColors.surface),
      'goldTextDark / surfaceDark': (AppColors.goldTextDark, AppColors.surfaceDark),
      'bubbleUserOn / bubbleUserStart': (
        AppColors.bubbleUserOn,
        AppColors.bubbleUserStart,
      ),
      'bubbleUserOn / bubbleUserEnd': (AppColors.bubbleUserOn, AppColors.bubbleUserEnd),
      'bubbleUserOnDark / bubbleUserStartDark': (
        AppColors.bubbleUserOnDark,
        AppColors.bubbleUserStartDark,
      ),
      'bubbleUserOnDark / bubbleUserEndDark': (
        AppColors.bubbleUserOnDark,
        AppColors.bubbleUserEndDark,
      ),
    };

    cases.forEach((name, pair) {
      test(name, () {
        expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      });
    });

    test('onSurfaceVariant / surface (light & dark)', () {
      final light = AppTheme.light.colorScheme;
      final dark = AppTheme.dark.colorScheme;
      expect(
        _contrast(light.onSurfaceVariant, light.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(dark.onSurfaceVariant, dark.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}

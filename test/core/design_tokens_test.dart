// Unit test — Design tokens (docs/DESIGN.md §2)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/design/tokens/app_colors.dart';
import 'package:virtual_heart/core/design/tokens/app_durations.dart';
import 'package:virtual_heart/core/design/tokens/app_sizes.dart';

void main() {
  group('AppColors', () {
    test('token utama Sakura Light punya nilai', () {
      expect(AppColors.background, const Color(0xFFFDF4F7));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.primary, const Color(0xFFC24D7E));
      expect(AppColors.primaryDeep, const Color(0xFF9E3A63));
      expect(AppColors.secondary, const Color(0xFF6D4FA8));
      expect(AppColors.accent, const Color(0xFFE8546E));
      expect(AppColors.gold, const Color(0xFFC9A227));
      expect(AppColors.textPrimary, const Color(0xFF241021));
      expect(AppColors.textOnPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.primarySoft, const Color(0xFFF8DCE7));
      expect(AppColors.secondarySoft, const Color(0xFFEFE6FA));
      expect(AppColors.divider, const Color(0xFFF2E1EA));
    });

    test('dark mode tersedia (disetel independen)', () {
      expect(AppColors.backgroundDark, const Color(0xFF120D14));
      expect(AppColors.primaryDark, const Color(0xFFF28CB0));
      expect(AppColors.textPrimaryDark, const Color(0xFFF7EFF5));
    });

    test('alias kompatibilitas menunjuk token baru', () {
      expect(AppColors.backgroundLight, AppColors.background);
      expect(AppColors.surfaceLight, AppColors.surface);
      expect(AppColors.heartRed, AppColors.accent);
      expect(AppColors.textPrimaryLight, AppColors.textPrimary);
    });
  });

  group('AppSizes', () {
    test('spacing scale sesuai DESIGN.md', () {
      expect(AppSizes.spaceXxs, 4);
      expect(AppSizes.spaceXs, 8);
      expect(AppSizes.spaceSm, 12);
      expect(AppSizes.spaceMd, 16);
      expect(AppSizes.spaceLg, 24);
      expect(AppSizes.spaceXl, 32);
      expect(AppSizes.spaceXxl, 48);
    });

    test('radius sesuai DESIGN.md', () {
      expect(AppSizes.radiusSm, 8);
      expect(AppSizes.radiusMd, 16);
      expect(AppSizes.radiusLg, 24);
      expect(AppSizes.radiusFull, 999);
    });

    test('target sentuh minimum 48 dp', () {
      expect(AppSizes.touchTarget, 48);
    });
  });

  group('AppDurations', () {
    test('durasi motion sesuai DESIGN.md', () {
      expect(AppDurations.durationFast, const Duration(milliseconds: 120));
      expect(AppDurations.durationNormal, const Duration(milliseconds: 240));
      expect(AppDurations.durationSlow, const Duration(milliseconds: 400));
    });
  });
}

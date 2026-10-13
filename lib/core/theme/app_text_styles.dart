import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';

/// Thang chữ CareNest (DESIGN.md §5.1). Không dùng độ đậm 800.
abstract final class AppTextStyles {
  static const fontFamily = 'BeVietnamPro';
  static const tabularFigures = [FontFeature.tabularFigures()];

  static TextTheme textTheme(TextTheme base) {
    return base
        .copyWith(
          displaySmall: const TextStyle(
            fontSize: 26,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: const TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
            fontFeatures: tabularFigures,
          ),
          headlineSmall: const TextStyle(
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: const TextStyle(
            fontSize: 17,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: const TextStyle(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: const TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: const TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          // 0,06em của cỡ 12 = 0,72 logical pixel
          labelSmall: const TextStyle(
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.72,
          ),
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );
  }
}

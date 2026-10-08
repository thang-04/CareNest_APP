import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';

/// Thang chữ CareNest (DESIGN.md §5.1). Body 16 để phụ huynh dễ đọc trên điện thoại.
abstract final class AppTextStyles {
  static const fontFamily = 'BeVietnamPro';

  static TextTheme textTheme(TextTheme base) {
    return base
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 24,
            height: 1.33,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            height: 1.33,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: const TextStyle(
            fontSize: 12,
            height: 1.33,
            fontWeight: FontWeight.w400,
          ),
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );
  }
}

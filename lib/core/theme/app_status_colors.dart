import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';

/// Tông hiển thị chung (DESIGN.md §6); feature tự map mã trạng thái sang tông.
enum AppStatusTone { neutral, info, warning, purple, danger, success, teal }

@immutable
class StatusToneColors {
  const StatusToneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;

  static StatusToneColors lerp(
    StatusToneColors a,
    StatusToneColors b,
    double t,
  ) {
    return StatusToneColors(
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      border: Color.lerp(a.border, b.border, t)!,
    );
  }
}

/// Màu semantic ngoài ColorScheme: success/warning/purple/teal và bộ màu chip theo tông.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.purple,
    required this.teal,
    required this.tones,
  });

  static const light = AppStatusColors(
    success: AppColors.success,
    warning: AppColors.warning,
    purple: AppColors.purple,
    teal: AppColors.teal,
    tones: {
      AppStatusTone.neutral: StatusToneColors(
        foreground: AppColors.textSecondary,
        background: AppColors.disabledContainer,
        border: AppColors.border,
      ),
      AppStatusTone.info: StatusToneColors(
        foreground: AppColors.brandBlue700,
        background: AppColors.primaryContainer,
        border: AppColors.focusRing,
      ),
      AppStatusTone.warning: StatusToneColors(
        foreground: AppColors.warningChipText,
        background: AppColors.warningContainer,
        border: AppColors.warningBorder,
      ),
      AppStatusTone.purple: StatusToneColors(
        foreground: AppColors.purpleText,
        background: AppColors.purpleContainer,
        border: AppColors.purpleBorder,
      ),
      AppStatusTone.danger: StatusToneColors(
        foreground: AppColors.dangerText,
        background: AppColors.dangerContainer,
        border: AppColors.dangerBorder,
      ),
      AppStatusTone.success: StatusToneColors(
        foreground: AppColors.successText,
        background: AppColors.successContainer,
        border: AppColors.successBorder,
      ),
      AppStatusTone.teal: StatusToneColors(
        foreground: AppColors.tealText,
        background: AppColors.tealContainer,
        border: AppColors.tealBorder,
      ),
    },
  );

  final Color success;
  final Color warning;
  final Color purple;
  final Color teal;
  final Map<AppStatusTone, StatusToneColors> tones;

  StatusToneColors tone(AppStatusTone tone) => tones[tone]!;

  static AppStatusColors of(BuildContext context) =>
      Theme.of(context).extension<AppStatusColors>() ?? light;

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? warning,
    Color? purple,
    Color? teal,
    Map<AppStatusTone, StatusToneColors>? tones,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      purple: purple ?? this.purple,
      teal: teal ?? this.teal,
      tones: tones ?? this.tones,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tones: {
        for (final key in AppStatusTone.values)
          key: StatusToneColors.lerp(tone(key), other.tone(key), t),
      },
    );
  }
}

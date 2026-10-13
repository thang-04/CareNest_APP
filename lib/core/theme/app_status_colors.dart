import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';

/// Tông trạng thái bản ghi (DESIGN.md §6.1); feature tự map mã BE sang tông.
enum AppStatusTone { gray, orange, blue, approval, red, green, teal }

/// Nghĩa phản hồi (DESIGN.md §4.2) cho banner, toast, nút danger.
enum AppFeedback { success, warning, danger, info }

@immutable
class ToneColors {
  const ToneColors({
    required this.main,
    required this.foreground,
    required this.background,
    required this.border,
  });

  /// Viền pha màu tông 34% trên trắng (§6.1).
  ToneColors.fromTone({
    required this.main,
    required this.foreground,
    required this.background,
  }) : border = Color.lerp(AppColors.surface, main, 0.34)!;

  final Color main;
  final Color foreground;
  final Color background;
  final Color border;
}

/// Token ngoài ColorScheme mà widget chung cần (DESIGN.md §4.3).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.tones,
    required this.feedback,
    required this.link,
    required this.linkPressed,
    required this.brandPressed,
    required this.focusRing,
    required this.textMuted,
    required this.textDisabled,
    required this.track,
    required this.surfaceMuted,
    required this.accent,
    required this.accentSoft,
    required this.accentText,
  });

  static final light = AppStatusColors(
    tones: {
      AppStatusTone.gray: ToneColors.fromTone(
        main: AppColors.toneGray,
        foreground: AppColors.toneGrayText,
        background: AppColors.toneGraySoft,
      ),
      AppStatusTone.orange: ToneColors.fromTone(
        main: AppColors.toneOrange,
        foreground: AppColors.toneOrangeText,
        background: AppColors.toneOrangeSoft,
      ),
      AppStatusTone.blue: ToneColors.fromTone(
        main: AppColors.toneBlue,
        foreground: AppColors.toneBlueText,
        background: AppColors.toneBlueSoft,
      ),
      AppStatusTone.approval: ToneColors.fromTone(
        main: AppColors.toneApproval,
        foreground: AppColors.toneApprovalText,
        background: AppColors.toneApprovalSoft,
      ),
      AppStatusTone.red: ToneColors.fromTone(
        main: AppColors.toneRed,
        foreground: AppColors.toneRedText,
        background: AppColors.toneRedSoft,
      ),
      AppStatusTone.green: ToneColors.fromTone(
        main: AppColors.toneGreen,
        foreground: AppColors.toneGreenText,
        background: AppColors.toneGreenSoft,
      ),
      AppStatusTone.teal: ToneColors.fromTone(
        main: AppColors.toneTeal,
        foreground: AppColors.toneTealText,
        background: AppColors.toneTealSoft,
      ),
    },
    feedback: const {
      AppFeedback.success: ToneColors(
        main: AppColors.success,
        foreground: AppColors.successText,
        background: AppColors.successSoft,
        border: AppColors.successBorder,
      ),
      AppFeedback.warning: ToneColors(
        main: AppColors.warning,
        foreground: AppColors.warningText,
        background: AppColors.warningSoft,
        border: AppColors.warningBorder,
      ),
      AppFeedback.danger: ToneColors(
        main: AppColors.danger,
        foreground: AppColors.dangerText,
        background: AppColors.dangerSoft,
        border: AppColors.dangerBorder,
      ),
      AppFeedback.info: ToneColors(
        main: AppColors.info,
        foreground: AppColors.infoText,
        background: AppColors.infoSoft,
        border: AppColors.infoBorder,
      ),
    },
    link: AppColors.primary,
    linkPressed: AppColors.primaryPressed,
    brandPressed: AppColors.brandPressed,
    focusRing: AppColors.focusRing,
    textMuted: AppColors.textMuted,
    textDisabled: AppColors.textDisabled,
    track: AppColors.track,
    surfaceMuted: AppColors.surfaceMuted,
    accent: AppColors.accent,
    accentSoft: AppColors.accentSoft,
    accentText: AppColors.accentText,
  );

  final Map<AppStatusTone, ToneColors> tones;
  final Map<AppFeedback, ToneColors> feedback;

  /// Link, icon nhấn, focus (`primary` của CareNest, khác `ColorScheme.primary`).
  final Color link;
  final Color linkPressed;
  final Color brandPressed;
  final Color focusRing;
  final Color textMuted;
  final Color textDisabled;
  final Color track;
  final Color surfaceMuted;
  final Color accent;
  final Color accentSoft;
  final Color accentText;

  ToneColors tone(AppStatusTone tone) => tones[tone]!;
  ToneColors feedbackOf(AppFeedback kind) => feedback[kind]!;

  static AppStatusColors of(BuildContext context) =>
      Theme.of(context).extension<AppStatusColors>() ?? light;

  @override
  AppStatusColors copyWith({Map<AppStatusTone, ToneColors>? tones}) {
    return AppStatusColors(
      tones: tones ?? this.tones,
      feedback: feedback,
      link: link,
      linkPressed: linkPressed,
      brandPressed: brandPressed,
      focusRing: focusRing,
      textMuted: textMuted,
      textDisabled: textDisabled,
      track: track,
      surfaceMuted: surfaceMuted,
      accent: accent,
      accentSoft: accentSoft,
      accentText: accentText,
    );
  }

  // Chỉ có Light theme (§4.4) ⇒ không nội suy màu giữa hai bộ
  @override
  AppStatusColors lerp(AppStatusColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

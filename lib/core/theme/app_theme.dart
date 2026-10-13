import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';

/// Light theme duy nhất (DESIGN.md §4.3, §4.4, §9).
ThemeData buildLightTheme() {
  // ColorScheme.primary = brand (nền nút chính), không phải token `primary` (link) — §4.3
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: AppColors.onBrand,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.onBrand,
    secondary: AppColors.primary,
    onSecondary: AppColors.surface,
    secondaryContainer: AppColors.primarySoft,
    onSecondaryContainer: AppColors.onBrand,
    error: AppColors.danger,
    onError: AppColors.surface,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.dangerText,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.surfaceMuted,
    surfaceContainer: AppColors.surfaceMuted,
    surfaceContainerHigh: AppColors.track,
    surfaceContainerHighest: AppColors.track,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    scrim: AppColors.overlay,
    shadow: Color(0xFF101828),
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.surface,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppTextStyles.fontFamily,
    scaffoldBackgroundColor: AppColors.background,
  );
  final textTheme = AppTextStyles.textTheme(base.textTheme);

  const pill = StadiumBorder();
  const buttonSize = Size(64, AppSizes.buttonHeight);
  const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.space6);

  return base.copyWith(
    textTheme: textTheme,
    extensions: [AppStatusColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: AppSizes.appBarHeight,
      titleTextStyle: textTheme.titleLarge,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
        disabledBackgroundColor: AppColors.track,
        disabledForegroundColor: AppColors.textDisabled,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: pill,
        elevation: 0,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: pill,
        side: const BorderSide(color: AppColors.borderStrong),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(AppSizes.minimumTapTarget, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.surface,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.surface),
      side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs + 2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: AppColors.overlay,
      showDragHandle: true,
      dragHandleColor: AppColors.borderStrong,
      dragHandleSize: Size(40, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxxl)),
      ),
    ),
    // Thanh đáy cao 72, nhãn luôn hiện, viên 64×32 `primarySoft` sau icon (§8.1)
    navigationBarTheme: NavigationBarThemeData(
      height: AppSizes.bottomNavigationHeight,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.primarySoft,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: AppSizes.iconNavigation,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelSmall?.copyWith(
          letterSpacing: 0,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.dangerText,
      textColor: AppColors.surface,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';

/// Light theme duy nhất theo Figma App phẳng (user chốt 14/11; DESIGN.md §4.3, §9).
ThemeData buildLightTheme() {
  // ColorScheme.primary = brand (nền nút chính, chữ trắng) — §4.3
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: AppColors.onBrand,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryText,
    secondary: AppColors.primary,
    onSecondary: AppColors.surface,
    secondaryContainer: AppColors.primarySoft,
    onSecondaryContainer: AppColors.primaryText,
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

  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  );
  const buttonSize = Size(64, AppSizes.buttonHeight);
  const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.space6);

  return base.copyWith(
    textTheme: textTheme,
    extensions: [AppStatusColors.light],
    // Figma: thanh tiêu đề trắng, kẻ dưới mảnh tách khỏi nền màn
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
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
        disabledBackgroundColor: AppColors.borderStrong,
        disabledForegroundColor: AppColors.surface,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: control,
        elevation: 0,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: control,
        side: const BorderSide(color: AppColors.primary),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(AppSizes.minimumTapTarget, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
        shape: control,
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
    // Thanh đáy phẳng cao 64, nhãn luôn hiện, ô chọn `primarySoft` sau icon (Figma App)
    navigationBarTheme: NavigationBarThemeData(
      height: AppSizes.bottomNavigationHeight,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.primarySoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: AppSizes.iconNavigation,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
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
              : AppColors.textMuted,
        ),
      ),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.danger,
      textColor: AppColors.surface,
    ),
    // TextField thô (vd. ô thân nhiệt): viền `outline` bo 8, focus viền `primary` (mặc định M3).
    // Chỉ đặt `border` để ô tự vẽ khung (`InputBorder.none`) không bị theme thêm viền.
    // Không đặt contentPadding: theme cộng vào cả ô `isCollapsed` của AppTextField
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';

/// Light theme duy nhất ở bản đầu (DESIGN.md §4.3, §9.1).
ThemeData buildLightTheme() {
  // fromSeed không giữ đúng #1565E0 ⇒ ghi đè các role đã duyệt (DESIGN §4.2)
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.brandBlue700,
        error: AppColors.danger,
        onError: AppColors.textInverse,
        errorContainer: AppColors.dangerContainer,
        onErrorContainer: AppColors.dangerText,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        surfaceContainerLowest: AppColors.surface,
        surfaceContainerLow: AppColors.surfaceSoft,
        surfaceContainerHighest: AppColors.disabledContainer,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.textInverse,
        surfaceTint: Colors.transparent,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppTextStyles.fontFamily,
    scaffoldBackgroundColor: AppColors.background,
  );
  final textTheme = AppTextStyles.textTheme(base.textTheme);

  const smallShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.small)),
  );
  const buttonMinimumSize = Size(64, AppSizes.buttonMinHeight);
  const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.space5);

  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.small)),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    textTheme: textTheme,
    extensions: const [AppStatusColors.light],
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonMinimumSize,
        padding: buttonPadding,
        shape: smallShape,
        textStyle: textTheme.labelLarge,
        disabledBackgroundColor: AppColors.disabledContainer,
        disabledForegroundColor: AppColors.disabled,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonMinimumSize,
        padding: buttonPadding,
        shape: smallShape,
        textStyle: textTheme.labelLarge,
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.disabled,
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(
          AppSizes.minimumTapTarget,
          AppSizes.buttonMinHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
        shape: smallShape,
        textStyle: textTheme.labelLarge,
        disabledForegroundColor: AppColors.disabled,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      border: inputBorder(AppColors.borderStrong),
      enabledBorder: inputBorder(AppColors.borderStrong),
      focusedBorder: inputBorder(AppColors.primary, 2),
      errorBorder: inputBorder(AppColors.danger),
      focusedErrorBorder: inputBorder(AppColors.danger, 2),
      disabledBorder: inputBorder(AppColors.border),
      labelStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.primary,
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
      helperStyle: textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
      ),
      errorStyle: textTheme.labelSmall?.copyWith(color: AppColors.dangerText),
      errorMaxLines: 3,
      helperMaxLines: 3,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textInverse,
      ),
      shape: smallShape,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.skeleton,
    ),
  );
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_button.dart';

/// Trạng thái rỗng: tranh 168×124 (tạm khối màu khi chưa có tranh), tiêu đề, giải thích, hành động.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.calendarOff,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      visual: Container(
        width: AppSizes.emptyIllustrationWidth,
        height: AppSizes.emptyIllustrationHeight,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Icon(icon, size: 44, color: AppStatusColors.of(context).link),
      ),
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : AppButton(label: actionLabel!, onPressed: onAction, small: true),
    );
  }
}

/// Trạng thái lỗi: icon (không tranh), câu cụ thể, "Thử lại".
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final danger = AppStatusColors.of(context).feedbackOf(AppFeedback.danger);
    return _StateLayout(
      visual: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: danger.background,
          shape: BoxShape.circle,
        ),
        child: Icon(AppIcons.cloudOff, size: 32, color: danger.foreground),
      ),
      title: title,
      message: message,
      action: AppButton(
        label: 'Thử lại',
        icon: AppIcons.refresh,
        onPressed: onRetry,
        variant: AppButtonVariant.secondary,
        small: true,
      ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.visual,
    required this.title,
    required this.message,
    this.action,
  });

  final Widget visual;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space10,
        horizontal: AppSpacing.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          visual,
          const SizedBox(height: AppSpacing.space4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.space4),
            action!,
          ],
        ],
      ),
    );
  }
}

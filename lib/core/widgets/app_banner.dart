import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';

enum AppBannerKind { info, warning, danger, success, neutral }

/// Banner nền nhạt theo nghĩa, không viền, bo 16, nổi nhẹ (DESIGN.md §7.1).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.kind = AppBannerKind.info,
    this.title,
    this.icon,
  });

  final String message;
  final AppBannerKind kind;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final status = AppStatusColors.of(context);
    final colors = switch (kind) {
      AppBannerKind.info => status.feedbackOf(AppFeedback.info),
      AppBannerKind.warning => status.feedbackOf(AppFeedback.warning),
      AppBannerKind.danger => status.feedbackOf(AppFeedback.danger),
      AppBannerKind.success => status.feedbackOf(AppFeedback.success),
      AppBannerKind.neutral => status.tone(AppStatusTone.gray),
    };
    final defaultIcon = switch (kind) {
      AppBannerKind.danger => AppIcons.alertCircle,
      AppBannerKind.warning => AppIcons.alertTriangle,
      AppBannerKind.success => AppIcons.check,
      _ => AppIcons.info,
    };
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: kind == AppBannerKind.danger,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon ?? defaultIcon,
              size: AppSizes.iconInline,
              color: colors.foreground,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

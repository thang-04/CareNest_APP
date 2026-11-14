import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Đầu tab Chờ xử lý của BGH (Figma PHT 02, HT 02): thanh trắng kẻ đáy như AppBar, mũi tên về
/// trang chủ của vai trò, tiêu đề và số việc BE trả.
class ApprovalsHeader extends StatelessWidget {
  const ApprovalsHeader({
    super.key,
    required this.count,
    required this.homePath,
  });

  /// Null ⇒ đang tải, chưa hiện số.
  final int? count;

  /// Tab gốc không có màn để quay lại ⇒ mũi tên chuyển về tab trang chủ.
  final String homePath;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = this.count;
    return Material(
      color: AppColors.surface,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top,
          left: AppSpacing.space1,
          right: AppSpacing.pagePadding,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.appBarHeight),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(AppIcons.back),
                tooltip: 'Về trang chủ',
                onPressed: () => context.go(homePath),
              ),
              const SizedBox(width: AppSpacing.space1),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Chờ xử lý', style: textTheme.titleLarge),
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '$count việc',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

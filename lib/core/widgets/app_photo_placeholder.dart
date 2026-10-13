import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';

/// Khối giữ chỗ ảnh (bữa ăn, hoạt động). Ảnh thật chỉ tải qua URL có auth khi có API;
/// dữ liệu giả không dùng ảnh trẻ thật (AGENTS.md nguyên tắc 4).
class AppPhotoPlaceholder extends StatelessWidget {
  const AppPhotoPlaceholder({
    super.key,
    this.caption,
    this.moreCount = 0,
    this.aspectRatio = 4 / 3,
  });

  /// Chữ dưới ảnh, vd. "Bữa trưa".
  final String? caption;

  /// Số ảnh còn lại hiển thị "+N" phủ lên ô cuối.
  final int moreCount;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = [
      'Ảnh',
      ?caption,
      if (moreCount > 0) 'và $moreCount ảnh khác',
    ].join(' ');
    return Semantics(
      container: true,
      image: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: moreCount > 0
                    ? AppColors.textMuted
                    : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: moreCount > 0
                  ? Text(
                      '+$moreCount',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.surface,
                      ),
                    )
                  : const Icon(
                      AppIcons.image,
                      size: 28,
                      color: AppColors.primaryBorder,
                    ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

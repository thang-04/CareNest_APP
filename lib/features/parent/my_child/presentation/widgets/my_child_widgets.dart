import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';

/// Nhãn đánh giá hằng ngày; tông theo tiêu chí, nghĩa nằm ở chữ (không chỉ màu).
class ReviewTagWrap extends StatelessWidget {
  const ReviewTagWrap({super.key, required this.tags});

  final List<ReviewTag> tags;

  static AppStatusTone toneOf(ReviewCriterion criterion) => switch (criterion) {
    // Không dùng tông blue: badge blue không icon tự có chấm, lệch với các nhãn khác
    ReviewCriterion.health ||
    ReviewCriterion.emotion ||
    ReviewCriterion.behavior => AppStatusTone.green,
    ReviewCriterion.learning => AppStatusTone.teal,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: [
        for (final tag in tags)
          AppStatusBadge(label: tag.label, tone: toneOf(tag.criterion)),
      ],
    );
  }
}

/// Dòng nhãn – giá trị trong card thông tin (hồ sơ bé, ngày điểm danh).
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space1),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          children: [
            TextSpan(
              text: value,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

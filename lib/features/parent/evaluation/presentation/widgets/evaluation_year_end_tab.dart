import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_widgets.dart';

/// Mục Cuối năm (OBS-28): phiếu đánh giá sự phát triển; chỉ "Lưu ý cho cha mẹ", không có
/// cân đo cuối năm — số đo xem ở Sổ sức khỏe (user 18/11).
class EvaluationYearEndTab extends StatelessWidget {
  const EvaluationYearEndTab({super.key, required this.yearEnd});

  final YearEndResult? yearEnd;

  @override
  Widget build(BuildContext context) {
    final result = yearEnd;
    if (result == null || result.status == PeriodStatus.pending) {
      return const AppEmptyState(
        icon: AppIcons.school,
        title: 'Chưa có đánh giá cuối năm',
        message: 'Phiếu có sau khi kết thúc học kỳ II và cô xác nhận.',
      );
    }
    final firstOpen = result.domains.indexWhere(
      (domain) => domain.goals.any((goal) => !goal.met),
    );
    final confirmedBy = result.confirmedBy;
    final confirmedAt = result.confirmedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: EvaluationResultSummary(
            eyebrow: 'Phiếu đánh giá sự phát triển',
            title: 'Năm học ${result.schoolYear}',
            meta: result.ageGroup,
            met: result.metGoals,
            total: result.totalGoals,
            unit: 'mục tiêu đạt',
            badge: result.programCompleted == true
                ? const AppStatusBadge(
                    label: 'Hoàn thành chương trình mầm non',
                    tone: AppStatusTone.green,
                    icon: AppIcons.school,
                  )
                : null,
          ),
        ),
        if (result.teacherComment != null || result.noteForParent != null) ...[
          const SizedBox(height: AppSpacing.cardGap),
          _CommentCard(result: result),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        const EvaluationSectionTitle('Theo lĩnh vực'),
        const SizedBox(height: AppSpacing.space3),
        AppCard(
          flush: true,
          child: AppDividedColumn(
            children: [
              for (var i = 0; i < result.domains.length; i++)
                DomainTile(
                  domain: result.domains[i],
                  initiallyExpanded: i == firstOpen,
                ),
            ],
          ),
        ),
        if (confirmedBy != null && confirmedAt != null) ...[
          const SizedBox(height: AppSpacing.space4),
          ConfirmedNote(by: confirmedBy, at: confirmedAt),
        ],
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.result});

  final YearEndResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final comment = result.teacherComment;
    final teacher = result.teacherName;
    final commentedAt = result.commentedAt;
    final note = result.noteForParent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comment != null) ...[
            const EvaluationSectionTitle('Nhận xét của cô'),
            const SizedBox(height: AppSpacing.space2),
            Text(comment, style: textTheme.bodyLarge),
            if (teacher != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                commentedAt == null
                    ? teacher
                    : '$teacher · ${DateLabels.date(commentedAt)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
          if (comment != null && note != null)
            const Divider(height: AppSpacing.space8),
          if (note != null) ...[
            Text('Lưu ý cho gia đình', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.space1),
            Text(note, style: textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/health_book/domain/health_book.dart';
import 'package:carenest_app/features/parent/health_book/presentation/health_labels.dart';
import 'package:carenest_app/features/parent/health_book/presentation/widgets/health_widgets.dart';

/// Tab Đợt khám: mỗi đợt một thẻ (tên, ngày, bác sĩ, mức theo dõi, kết luận ngắn);
/// chạm để mở màn Chi tiết đợt khám (user 17/11).
class HealthExamsTab extends StatelessWidget {
  const HealthExamsTab({
    super.key,
    required this.exams,
    required this.onOpenExam,
  });

  final List<HealthExam> exams;
  final ValueChanged<String> onOpenExam;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HealthSectionHeader(
          title: 'Đợt khám sức khỏe',
          caption: 'Bác sĩ khám tại trường mỗi năm học một lần.',
        ),
        const SizedBox(height: AppSpacing.space3),
        if (exams.isEmpty) ...[
          const AppEmptyState(
            icon: AppIcons.clipboardCheck,
            title: 'Chưa có kết quả khám',
            message: 'Kết quả hiện ở đây sau khi bác sĩ khám và có kết luận.',
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
        for (final exam in exams) ...[
          _ExamCard(exam: exam, onTap: () => onOpenExam(exam.id)),
          const SizedBox(height: AppSpacing.space3),
        ],
        Text(
          'Kết luận do bác sĩ đưa ra khi khám tại trường, giáo viên nhập lại. Có thắc mắc, phụ huynh trao đổi trực tiếp với cô giáo.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onTap});

  final HealthExam exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = HealthLabels.followUp(exam.followUp);
    return AppCard(
      flush: true,
      child: AppListRow(
        title: exam.name,
        titleMaxLines: 3,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${DateLabels.date(exam.date)} · ${exam.doctorName}'),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppStatusBadge(label: label, tone: tone),
                if (exam.issueText case final issue?) Text('Kết luận: $issue'),
              ],
            ),
          ],
        ),
        showChevron: true,
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';
import 'package:carenest_app/features/parent/rewards/presentation/rewards_status.dart';
import 'package:carenest_app/features/parent/rewards/presentation/widgets/rewards_widgets.dart';

/// Mục Cuối năm (OBS-14, PAR-03): danh hiệu và Lời cô chỉ hiện khi Hiệu trưởng đã duyệt danh sách của lớp.
class RewardsYearEndTab extends StatelessWidget {
  const RewardsYearEndTab({
    super.key,
    this.schoolYear,
    this.yearEnd,
    this.totals,
  });

  final String? schoolYear;
  final YearEndReward? yearEnd;
  final RewardTotals? totals;

  @override
  Widget build(BuildContext context) {
    final yearEnd = this.yearEnd;
    final totals = this.totals;
    final note = yearEnd?.teacherNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (yearEnd == null)
          const RewardNotice(
            icon: AppIcons.trophy,
            title: 'Chưa có danh hiệu cuối năm',
            message: 'Danh hiệu hiện ở đây sau khi Hiệu trưởng duyệt.',
          )
        else if (yearEnd.titles.isEmpty) ...[
          // User 18/11: đã duyệt mà bé không có danh hiệu ⇒ câu nhẹ nhàng
          const RewardNotice(
            icon: AppIcons.ticket,
            title: 'Năm học này bé chưa có danh hiệu',
            message: 'Phiếu bé đã nhận vẫn xem ở mục Tuần và Tháng.',
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.cardGap),
            AppCard(
              child: _TeacherNote(note: note, approvedAt: yearEnd.approvedAt),
            ),
          ],
        ] else
          _TitlesCard(schoolYear: schoolYear, yearEnd: yearEnd),
        if (totals != null) ...[
          const SizedBox(height: AppSpacing.cardGap),
          _TotalsCard(totals: totals),
        ],
      ],
    );
  }
}

class _TitlesCard extends StatelessWidget {
  const _TitlesCard({required this.schoolYear, required this.yearEnd});

  final String? schoolYear;
  final YearEndReward yearEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = yearEnd.teacherNote;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (schoolYear case final year?) ...[
            Text(
              'Năm học $year'.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space1),
          ],
          Semantics(
            header: true,
            child: Text('Danh hiệu của bé', style: textTheme.headlineSmall),
          ),
          for (final title in yearEnd.titles) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                AppIconTile(
                  icon: RewardsStatus.titleIcon(title),
                  tone: RewardsStatus.earned,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(child: Text(title, style: textTheme.titleSmall)),
              ],
            ),
          ],
          if (note != null) ...[
            const Divider(height: AppSpacing.space8),
            _TeacherNote(note: note, approvedAt: yearEnd.approvedAt),
          ] else if (yearEnd.approvedAt case final approvedAt?) ...[
            const Divider(height: AppSpacing.space8),
            _ApprovedLine(approvedAt: approvedAt),
          ],
        ],
      ),
    );
  }
}

/// Ghi chú của cô trong danh sách khen thưởng (user 18/11: phụ huynh xem được).
class _TeacherNote extends StatelessWidget {
  const _TeacherNote({required this.note, required this.approvedAt});

  final String note;
  final DateTime? approvedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lời cô', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.space1),
        Text(note, style: textTheme.bodyLarge),
        if (approvedAt case final approvedAt?) ...[
          const SizedBox(height: AppSpacing.space4),
          _ApprovedLine(approvedAt: approvedAt),
        ],
      ],
    );
  }
}

class _ApprovedLine extends StatelessWidget {
  const _ApprovedLine({required this.approvedAt});

  final DateTime approvedAt;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hiệu trưởng duyệt ngày ${DateLabels.date(approvedAt)}',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final RewardTotals totals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            children: [
              const RewardsSectionTitle('Cả năm học'),
              Text(
                'Đến ${DateLabels.date(totals.asOf)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          AppStatRow(
            tiles: [
              AppStatTile(value: '${totals.flags}', label: 'cờ bé ngoan'),
              AppStatTile(
                value: '${totals.weeklyTickets}',
                label: 'phiếu ${RewardsStatus.weeklyTicket}',
              ),
              AppStatTile(
                value: '${totals.monthlyTickets}',
                label: 'phiếu ${RewardsStatus.monthlyTicket}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

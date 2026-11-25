import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';
import 'package:carenest_app/features/parent/rewards/presentation/rewards_status.dart';
import 'package:carenest_app/features/parent/rewards/presentation/widgets/rewards_widgets.dart';

/// Mục Tháng (OBS-10): tháng mới nhất có ô phiếu từng tuần; các tháng trước, mới nhất trước.
class RewardsMonthTab extends StatelessWidget {
  const RewardsMonthTab({super.key, required this.months, required this.rules});

  /// Mới nhất trước
  final List<RewardMonth> months;

  /// null: BE chưa trả ngưỡng ⇒ không có câu quy tắc (Q2).
  final RewardRules? rules;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.ticket,
        title: 'Chưa có phiếu Bé ngoan',
        message: 'Phiếu hiện ở đây khi cô phát.',
      );
    }
    final past = months.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LatestMonthCard(month: months.first, rules: rules),
        if (past.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          const RewardsSectionTitle('Các tháng trước'),
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            flush: true,
            child: AppDividedColumn(
              children: [
                for (final month in past)
                  AppListRow(
                    title: DateLabels.month(month.month),
                    // Nhãn dài ⇒ đặt dưới số phiếu, chữ lớn không tràn
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${month.weeklyTickets} phiếu '
                          '${RewardsStatus.weeklyTicket}',
                        ),
                        if (month.ticket != null) ...[
                          const SizedBox(height: AppSpacing.space2),
                          const TicketBadge.monthly(),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestMonthCard extends StatelessWidget {
  const _LatestMonthCard({required this.month, required this.rules});

  final RewardMonth month;

  /// null: BE chưa trả ngưỡng ⇒ không có câu quy tắc (Q2).
  final RewardRules? rules;

  @override
  Widget build(BuildContext context) {
    final ticket = month.ticket;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RewardPeriodHeader(
            eyebrow: month.ongoing ? 'Tháng này' : 'Tháng vừa qua',
            title: DateLabels.month(month.month),
            count: month.weeklyTickets,
            unit: 'phiếu ${RewardsStatus.weeklyTicket} trong tháng',
          ),
          if (month.weeks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            WeekTicketStrip(weeks: month.weeks),
          ],
          const Divider(height: AppSpacing.space8),
          if (ticket != null)
            RewardIssuedRow(
              icon: AppIcons.medal,
              title: 'Bé nhận phiếu ${RewardsStatus.monthlyTicket}',
              ticket: ticket,
            )
          else if (rules case final rules?)
            RewardRuleHint(
              'Từ ${rules.monthMinWeeklyTickets} phiếu '
              '${RewardsStatus.weeklyTicket} trong tháng, cô xét phiếu '
              '${RewardsStatus.monthlyTicket} khi hết tháng.',
            ),
        ],
      ),
    );
  }
}

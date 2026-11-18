import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';
import 'package:carenest_app/features/parent/rewards/presentation/rewards_status.dart';
import 'package:carenest_app/features/parent/rewards/presentation/widgets/rewards_widgets.dart';

/// Mục Tuần (OBS-10): tuần mới nhất có cờ từng ngày; các tuần trước nhóm theo tháng, mới nhất trước.
class RewardsWeekTab extends StatefulWidget {
  const RewardsWeekTab({
    super.key,
    required this.weeks,
    required this.rules,
    required this.onOpenDailyEvaluation,
  });

  /// Mới nhất trước
  final List<RewardWeek> weeks;
  final RewardRules rules;
  final VoidCallback onOpenDailyEvaluation;

  @override
  State<RewardsWeekTab> createState() => _RewardsWeekTabState();
}

class _RewardsWeekTabState extends State<RewardsWeekTab> {
  static const _monthsPerPage = 2;
  var _monthsShown = _monthsPerPage;

  @override
  Widget build(BuildContext context) {
    if (widget.weeks.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.flagOutline,
        title: 'Chưa có cờ bé ngoan',
        message: 'Cờ hiện ở đây sau khi cô đánh giá mỗi ngày.',
      );
    }
    final textTheme = Theme.of(context).textTheme;
    final months = _byMonth(widget.weeks.skip(1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LatestWeekCard(
          week: widget.weeks.first,
          rules: widget.rules,
          onOpenDailyEvaluation: widget.onOpenDailyEvaluation,
        ),
        if (months.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          const RewardsSectionTitle('Các tuần trước'),
          for (final (month, weeks) in months.take(_monthsShown)) ...[
            const SizedBox(height: AppSpacing.space3),
            Semantics(
              header: true,
              child: Text(
                DateLabels.month(month),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            AppCard(
              flush: true,
              child: AppDividedColumn(
                children: [
                  for (final week in weeks)
                    AppListRow(
                      title: RewardsStatus.days(week.from, week.to),
                      subtitle: _FlagCount(week.flags),
                      trailing: week.ticket == null
                          ? null
                          : const TicketBadge.weekly(),
                    ),
                ],
              ),
            ),
          ],
          if (months.length > _monthsShown) ...[
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: AppButton(
                label: 'Xem các tuần trước',
                variant: AppButtonVariant.text,
                small: true,
                trailingIcon: AppIcons.chevronDown,
                onPressed: () => setState(() => _monthsShown += _monthsPerPage),
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Nhóm tuần theo tháng của ngày đầu tuần, giữ thứ tự mới nhất trước.
  static List<(DateTime, List<RewardWeek>)> _byMonth(
    Iterable<RewardWeek> weeks,
  ) {
    final groups = <(DateTime, List<RewardWeek>)>[];
    for (final week in weeks) {
      final month = DateTime(week.from.year, week.from.month);
      if (groups.isEmpty || groups.last.$1 != month) {
        groups.add((month, [week]));
      } else {
        groups.last.$2.add(week);
      }
    }
    return groups;
  }
}

class _LatestWeekCard extends StatelessWidget {
  const _LatestWeekCard({
    required this.week,
    required this.rules,
    required this.onOpenDailyEvaluation,
  });

  final RewardWeek week;
  final RewardRules rules;
  final VoidCallback onOpenDailyEvaluation;

  @override
  Widget build(BuildContext context) {
    final ticket = week.ticket;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RewardPeriodHeader(
            eyebrow: week.ongoing ? 'Tuần này' : 'Tuần vừa qua',
            title: RewardsStatus.days(week.from, week.to),
            count: week.flags,
            unit: 'cờ trong tuần',
          ),
          if (week.days.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            FlagDayStrip(days: week.days),
          ],
          const Divider(height: AppSpacing.space8),
          if (ticket != null)
            RewardIssuedRow(
              icon: AppIcons.ticket,
              title: 'Bé nhận phiếu ${RewardsStatus.weeklyTicket}',
              ticket: ticket,
            )
          else
            RewardRuleHint(
              'Từ ${rules.weekMinFlags} cờ trong tuần, cô xét phiếu '
              '${RewardsStatus.weeklyTicket} khi hết tuần.',
            ),
          const SizedBox(height: AppSpacing.space2),
          AppButton(
            label: 'Xem đánh giá từng ngày',
            variant: AppButtonVariant.text,
            small: true,
            trailingIcon: AppIcons.chevronRight,
            onPressed: onOpenDailyEvaluation,
          ),
        ],
      ),
    );
  }
}

class _FlagCount extends StatelessWidget {
  const _FlagCount(this.flags);

  final int flags;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          AppIcons.flagOutline,
          size: AppSizes.iconBadge,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.space1),
        Text('$flags cờ'),
      ],
    );
  }
}

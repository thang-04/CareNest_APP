import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';
import 'package:carenest_app/features/parent/rewards/presentation/rewards_status.dart';

/// Tiêu đề một phần của trang Khen thưởng.
class RewardsSectionTitle extends StatelessWidget {
  const RewardsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Đầu thẻ kỳ mới nhất: nhãn kỳ, tên kỳ, số đếm BE trả kèm đơn vị.
class RewardPeriodHeader extends StatelessWidget {
  const RewardPeriodHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.count,
    required this.unit,
  });

  final String eyebrow;
  final String title;
  final int count;

  /// "cờ trong tuần", "phiếu Bé ngoan trong tháng"
  final String unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(title, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.space4),
        Semantics(
          container: true,
          label: '$count $unit',
          excludeSemantics: true,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.space2,
            children: [
              Text('$count', style: textTheme.headlineMedium),
              Text(
                unit,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cờ từng ngày học trong tuần; mỗi ô có chữ hoặc icon, không chỉ bằng màu.
class FlagDayStrip extends StatelessWidget {
  const FlagDayStrip({super.key, required this.days});

  final List<FlagDay> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.space2),
          Expanded(child: _FlagDayPill(day: days[i])),
        ],
      ],
    );
  }
}

class _FlagDayPill extends StatelessWidget {
  const _FlagDayPill({required this.day});

  final FlagDay day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final earned = status.tone(RewardsStatus.earned);
    final gray = status.tone(AppStatusTone.gray);
    final (Color? fill, Color? edge, Color label) = switch (day.status) {
      FlagDayStatus.flagged => (earned.background, null, earned.foreground),
      FlagDayStatus.noFlag => (
        AppColors.surfaceMuted,
        AppColors.border,
        AppColors.textMuted,
      ),
      FlagDayStatus.absent => (gray.background, null, gray.foreground),
      FlagDayStatus.pending => (
        null,
        AppColors.borderStrong,
        AppColors.textMuted,
      ),
    };
    final date = switch (day.status) {
      FlagDayStatus.flagged || FlagDayStatus.noFlag => AppColors.textPrimary,
      _ => label,
    };
    final mark = switch (day.status) {
      FlagDayStatus.flagged => Icon(
        AppIcons.flag,
        size: AppSizes.iconInline,
        color: label,
      ),
      FlagDayStatus.noFlag => Icon(
        AppIcons.minus,
        size: AppSizes.iconInline,
        color: label,
      ),
      FlagDayStatus.absent => _Fit(
        Text('Nghỉ', style: textTheme.labelSmall?.copyWith(color: label)),
      ),
      FlagDayStatus.pending => const SizedBox(height: AppSizes.iconInline),
    };
    return Semantics(
      container: true,
      label:
          '${DateLabels.weekdayDayMonth(day.date)}: '
          '${RewardsStatus.flagDay(day.status)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.cardGap),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: edge == null ? null : Border.all(color: edge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Fit(
              Text(
                DateLabels.weekdayShort(day.date),
                style: textTheme.labelMedium?.copyWith(color: label),
              ),
            ),
            _Fit(
              Text(
                '${day.date.day}',
                style: textTheme.titleMedium?.copyWith(color: date),
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            mark,
          ],
        ),
      ),
    );
  }
}

/// Ô phiếu Bé ngoan từng tuần trong tháng.
class WeekTicketStrip extends StatelessWidget {
  const WeekTicketStrip({super.key, required this.weeks});

  final List<WeekTicketSlot> weeks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < weeks.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.space2),
          Expanded(child: _WeekTicketCell(slot: weeks[i])),
        ],
      ],
    );
  }
}

class _WeekTicketCell extends StatelessWidget {
  const _WeekTicketCell({required this.slot});

  final WeekTicketSlot slot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final earned = AppStatusColors.of(context).tone(RewardsStatus.earned);
    final (
      Color? fill,
      Color? edge,
      Color mark,
      IconData icon,
    ) = switch (slot.status) {
      WeekTicketStatus.issued => (
        earned.background,
        null,
        earned.foreground,
        AppIcons.ticket,
      ),
      WeekTicketStatus.none => (
        AppColors.surfaceMuted,
        AppColors.border,
        AppColors.textMuted,
        AppIcons.minus,
      ),
      WeekTicketStatus.ongoing => (
        null,
        AppColors.borderStrong,
        AppColors.textMuted,
        AppIcons.clock,
      ),
    };
    final week = DateLabels.dayMonth(slot.from);
    return Semantics(
      container: true,
      label: 'Tuần $week: ${RewardsStatus.weekTicket(slot.status)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.cardGap),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: edge == null ? null : Border.all(color: edge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Fit(
              Text(
                week,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Icon(icon, size: AppSizes.iconInline, color: mark),
          ],
        ),
      ),
    );
  }
}

/// Ô hẹp (5 ô một hàng): chữ quá rộng khi phóng lớn thì co vừa ô thay vì tràn.
class _Fit extends StatelessWidget {
  const _Fit(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, child: child);
  }
}

/// Phiếu cô đã phát: ai phát, ngày nào.
class RewardIssuedRow extends StatelessWidget {
  const RewardIssuedRow({
    super.key,
    required this.icon,
    required this.title,
    required this.ticket,
  });

  final IconData icon;
  final String title;
  final IssuedTicket ticket;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        AppIconTile(icon: icon, tone: RewardsStatus.earned),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              Text(
                RewardsStatus.issued(ticket),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Câu ngưỡng (số lấy từ BE); chỉ nói "cô xét" vì cô chọn bé nhận phiếu (OBS-10).
class RewardRuleHint extends StatelessWidget {
  const RewardRuleHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          AppIcons.info,
          size: AppSizes.iconInline,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Nhãn phiếu đã nhận ở dòng danh sách.
class TicketBadge extends StatelessWidget {
  const TicketBadge.weekly({super.key})
    : label = RewardsStatus.weeklyTicket,
      icon = AppIcons.ticket;

  const TicketBadge.monthly({super.key})
    : label = RewardsStatus.monthlyTicket,
      icon = AppIcons.medal;

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Có phiếu $label',
      excludeSemantics: true,
      child: AppStatusBadge(
        label: label,
        tone: RewardsStatus.earned,
        icon: icon,
      ),
    );
  }
}

/// Thẻ báo ngắn khi chưa có danh hiệu.
class RewardNotice extends StatelessWidget {
  const RewardNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, tone: AppStatusTone.gray),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

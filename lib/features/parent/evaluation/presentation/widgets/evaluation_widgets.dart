import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/motion.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';

/// Tiêu đề một phần của trang Đánh giá.
class EvaluationSectionTitle extends StatelessWidget {
  const EvaluationSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Đổi kỳ đang xem (tuần, học kỳ) bằng ‹ ›; nút mờ khi hết kỳ.
class EvaluationPeriodStepper extends StatelessWidget {
  const EvaluationPeriodStepper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.previousLabel,
    required this.nextLabel,
    this.onPrevious,
    this.onNext,
  });

  final String title;
  final String subtitle;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton(
          tooltip: previousLabel,
          onPressed: onPrevious,
          icon: const Icon(AppIcons.back),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall,
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: nextLabel,
          onPressed: onNext,
          icon: const Icon(AppIcons.chevronRight),
        ),
      ],
    );
  }
}

/// Đầu thẻ kết quả: nhãn kỳ, số đạt / tổng (BE trả), thanh tỉ lệ, nhãn và ghi chú.
class EvaluationResultSummary extends StatelessWidget {
  const EvaluationResultSummary({
    super.key,
    required this.met,
    required this.total,
    required this.unit,
    this.eyebrow,
    this.title,
    this.meta,
    this.badge,
    this.caption,
  });

  final int met;
  final int total;

  /// "mục tiêu đạt", "lĩnh vực đạt"
  final String unit;
  final String? eyebrow;
  final String? title;
  final String? meta;
  final Widget? badge;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Text(
            eyebrow!.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
        if (title != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(title!, style: textTheme.headlineSmall),
        ],
        if (meta != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(meta!, style: muted),
        ],
        if (eyebrow != null || title != null || meta != null)
          const SizedBox(height: AppSpacing.space4),
        Semantics(
          container: true,
          label: '$met trên $total $unit',
          excludeSemantics: true,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.space2,
            children: [
              Text('$met/$total', style: textTheme.headlineMedium),
              Text(
                unit,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        // Thanh chỉ minh họa số đã ghi bằng chữ ngay trên
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : met / total,
              minHeight: AppSpacing.space2,
              color: status.tone(AppStatusTone.green).main,
              backgroundColor: status.track,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(height: AppSpacing.space4),
          badge!,
        ],
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Text(caption!, style: muted),
        ],
      ],
    );
  }
}

/// Đạt / Chưa đạt dạng chữ kèm icon (không chỉ bằng màu).
class ResultMark extends StatelessWidget {
  const ResultMark({super.key, required this.met});

  final bool met;

  @override
  Widget build(BuildContext context) {
    final tone = AppStatusColors.of(
      context,
    ).tone(met ? AppStatusTone.green : AppStatusTone.red);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? AppIcons.check : AppIcons.minus,
          size: AppSizes.iconInline,
          color: tone.foreground,
        ),
        const SizedBox(width: AppSpacing.space1),
        Text(
          met ? 'Đạt' : 'Chưa đạt',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: tone.foreground),
        ),
      ],
    );
  }
}

/// Nhóm MT cùng kết quả: trạng thái ghi một lần ở đầu nhóm, hiện đủ MT (user 18/11: không thu gọn).
class GoalGroup extends StatelessWidget {
  const GoalGroup({
    super.key,
    required this.met,
    required this.goals,
    this.describe,
    this.compact = false,
  });

  final bool met;
  final List<GoalResult> goals;

  /// Dòng phụ dưới MT (hoạt động trong ngày, số chủ đề đạt).
  final String? Function(GoalResult goal)? describe;

  /// Trong khối lĩnh vực: tiêu đề nhóm nhỏ hơn.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tone = AppStatusColors.of(
      context,
    ).tone(met ? AppStatusTone.green : AppStatusTone.red);
    final label = met ? 'Đạt' : 'Chưa đạt';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          header: true,
          label: '$label, ${goals.length} mục tiêu',
          excludeSemantics: true,
          child: Row(
            children: [
              Icon(
                met ? AppIcons.check : AppIcons.minus,
                size: AppSizes.iconInline,
                color: tone.foreground,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    style: compact
                        ? textTheme.labelMedium
                        : textTheme.titleSmall,
                    children: [
                      TextSpan(
                        text: ' (${goals.length})',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final goal in goals) ...[
          const SizedBox(height: AppSpacing.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: AppSizes.iconInline + AppSpacing.space2),
              Expanded(
                child: _GoalText(goal: goal, describe: describe),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GoalText extends StatelessWidget {
  const _GoalText({required this.goal, this.describe});

  final GoalResult goal;
  final String? Function(GoalResult goal)? describe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = describe?.call(goal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(goal.text, style: textTheme.bodyLarge),
        if (detail != null)
          Text(
            detail,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}

/// Một lĩnh vực (học kỳ, cuối năm) dạng mở/đóng; mở ra thấy hết MT: chưa đạt trước, đạt sau
/// (user 18/11: không cần nút "Xem").
class DomainTile extends StatefulWidget {
  const DomainTile({
    super.key,
    required this.domain,
    this.initiallyExpanded = false,
    this.describe,
  });

  final DomainResult domain;
  final bool initiallyExpanded;
  final String? Function(GoalResult goal)? describe;

  @override
  State<DomainTile> createState() => _DomainTileState();
}

class _DomainTileState extends State<DomainTile> {
  late var _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final domain = widget.domain;
    final met = domain.goals.where((goal) => goal.met).toList();
    final notMet = domain.goals.where((goal) => !goal.met).toList();
    final header = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.listRowMinHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingDense),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(domain.name, style: textTheme.titleSmall),
                      if ((domain.metGoals, domain.totalGoals) case (
                        final met?,
                        final total?,
                      ))
                        Text(
                          '$met/$total mục tiêu đạt',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (domain.met != null) ...[
                  const SizedBox(width: AppSpacing.space3),
                  ResultMark(met: domain.met!),
                ],
                const SizedBox(width: AppSpacing.space2),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  curve: AppMotion.curve,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.fast,
                  child: const Icon(
                    AppIcons.chevronDown,
                    size: AppSizes.iconInline,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(button: true, expanded: _expanded, child: header),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardGap,
              0,
              AppSpacing.cardGap,
              AppSpacing.cardGap,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingDense),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (domain.comment != null) ...[
                    Text(
                      'Cô nhận xét',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(domain.comment!, style: textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.space4),
                  ],
                  if (notMet.isNotEmpty)
                    GoalGroup(
                      met: false,
                      goals: notMet,
                      describe: widget.describe,
                      compact: true,
                    ),
                  if (met.isNotEmpty) ...[
                    if (notMet.isNotEmpty)
                      const SizedBox(height: AppSpacing.space4),
                    GoalGroup(
                      met: true,
                      goals: met,
                      describe: widget.describe,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Dòng cuối thẻ: ai xác nhận, ngày nào.
class ConfirmedNote extends StatelessWidget {
  const ConfirmedNote({super.key, required this.by, required this.at});

  final String by;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$by xác nhận ngày ${DateLabels.date(at)}',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
    );
  }
}

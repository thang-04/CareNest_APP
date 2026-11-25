import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/evaluation/domain/evaluation.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/evaluation_labels.dart';
import 'package:carenest_app/features/parent/evaluation/presentation/widgets/evaluation_widgets.dart';

/// Mục Ngày (OBS-13): ‹ › đổi tuần, chọn ngày; mở sẵn ngày gần nhất cô đã lưu.
class EvaluationDayTab extends StatefulWidget {
  const EvaluationDayTab({super.key, required this.weeks});

  /// Tuần mới nhất trước
  final List<EvaluationWeek> weeks;

  @override
  State<EvaluationDayTab> createState() => _EvaluationDayTabState();
}

class _EvaluationDayTabState extends State<EvaluationDayTab> {
  var _weekIndex = 0;
  late DateTime? _day = _defaultDay(0);

  DateTime? _defaultDay(int weekIndex) {
    if (widget.weeks.isEmpty) return null;
    final days = widget.weeks[weekIndex].days;
    final saved = days.where((day) => day.status == DayStatus.evaluated);
    return (saved.isEmpty ? days.last : saved.last).date;
  }

  void _showWeek(int index) {
    setState(() {
      _weekIndex = index;
      _day = _defaultDay(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weeks.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.clipboardCheck,
        title: 'Chưa có đánh giá ngày',
        message: 'Đánh giá hiện ở đây sau khi cô lưu mỗi ngày.',
      );
    }
    final week = widget.weeks[_weekIndex];
    final day = week.days.firstWhere(
      (item) => DateUtils.isSameDay(item.date, _day),
      orElse: () => week.days.last,
    );
    final dayLabel = DateLabels.dayMonth(day.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EvaluationPeriodStepper(
          title: week.label,
          subtitle: DateLabels.range(week.from, week.to),
          previousLabel: 'Tuần trước',
          nextLabel: 'Tuần sau',
          onPrevious: _weekIndex < widget.weeks.length - 1
              ? () => _showWeek(_weekIndex + 1)
              : null,
          onNext: _weekIndex > 0 ? () => _showWeek(_weekIndex - 1) : null,
        ),
        const SizedBox(height: AppSpacing.space2),
        AppDayStrip(
          days: [for (final item in week.days) item.date],
          selected: day.date,
          onChanged: (value) => setState(() => _day = value),
        ),
        const SizedBox(height: AppSpacing.space4),
        switch (day.status) {
          DayStatus.absent => AppEmptyState(
            icon: AppIcons.calendarOff,
            title: 'Bé nghỉ học ngày $dayLabel',
            message: 'Ngày bé nghỉ không có đánh giá.',
          ),
          DayStatus.notRecorded => AppEmptyState(
            icon: AppIcons.clock,
            title: 'Chưa có đánh giá ngày $dayLabel',
            message: 'Đánh giá sẽ hiện ở đây sau khi cô lưu.',
          ),
          DayStatus.evaluated => _DayDetail(day: day),
        },
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day});

  final DayEvaluation day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final emotion = day.emotion;
    final nap = day.nap;
    final participation = day.participation;
    final comment = day.comment;
    final teacher = day.teacherName;
    final savedAt = day.savedAt;
    final notMet = day.goals.where((goal) => !goal.met).toList();
    final met = day.goals.where((goal) => goal.met).toList();
    final facts = [
      _Fact(
        'Sức khỏe',
        day.healthSigns.isEmpty
            ? 'Bình thường'
            : day.healthSigns.map(EvaluationLabels.healthSign).join(', '),
        attention: day.healthSigns.isNotEmpty,
      ),
      if (emotion != null)
        _Fact(
          'Cảm xúc',
          EvaluationLabels.emotion(emotion),
          attention: EvaluationLabels.emotionNeedsAttention(emotion),
        ),
      if (day.meals.isNotEmpty)
        _Fact(
          'Ăn',
          EvaluationLabels.meals(day.meals),
          attention: day.meals.values.any(
            EvaluationLabels.eatingNeedsAttention,
          ),
        ),
      if (nap != null)
        _Fact(
          'Ngủ trưa',
          EvaluationLabels.nap(nap),
          attention: EvaluationLabels.napNeedsAttention(nap),
        ),
      _Fact(
        'Hành vi',
        day.behaviors.isEmpty
            ? 'Bình thường'
            : day.behaviors.map(EvaluationLabels.behavior).join(' · '),
        attention: day.behaviors.any(EvaluationLabels.behaviorNeedsAttention),
        wide: true,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (day.flagged) ...[
          AppBanner(
            kind: AppBannerKind.success,
            icon: AppIcons.flag,
            message: 'Bé được cờ ngày ${DateLabels.dayMonth(day.date)}',
          ),
          const SizedBox(height: AppSpacing.cardGap),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EvaluationSectionTitle('Sinh hoạt'),
              const SizedBox(height: AppSpacing.space4),
              _FactGrid(facts: facts),
            ],
          ),
        ),
        if (participation != null || day.goals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EvaluationSectionTitle('Học tập'),
                if (participation != null) ...[
                  const SizedBox(height: AppSpacing.space4),
                  _FactView(
                    fact: _Fact(
                      'Tham gia hoạt động',
                      EvaluationLabels.participation(participation),
                      attention: participation == Participation.passive,
                    ),
                  ),
                ],
                if (notMet.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  GoalGroup(
                    met: false,
                    goals: notMet,
                    describe: (goal) => goal.activity,
                  ),
                ],
                if (met.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  GoalGroup(
                    met: true,
                    goals: met,
                    describe: (goal) => goal.activity,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (comment != null) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EvaluationSectionTitle('Lời cô nhắn'),
                const SizedBox(height: AppSpacing.space2),
                Text(comment, style: textTheme.bodyLarge),
                if (teacher != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    savedAt == null
                        ? teacher
                        : '$teacher · ${DateLabels.time24(savedAt)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Một mặt của ngày: nhãn trên, giá trị dưới; mặt cần chú ý tô cam kèm icon.
class _Fact {
  const _Fact(
    this.label,
    this.value, {
    this.attention = false,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool attention;

  /// Chiếm cả hàng (chữ dài như danh sách hành vi)
  final bool wide;
}

/// Lưới 2 cột; mặt [_Fact.wide] chiếm cả hàng.
class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    _Fact? left;
    void addRow(_Fact first, _Fact? second) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _FactView(fact: first)),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: second == null
                  ? const SizedBox.shrink()
                  : _FactView(fact: second),
            ),
          ],
        ),
      );
    }

    for (final fact in facts) {
      if (fact.wide) {
        if (left != null) addRow(left, null);
        left = null;
        rows.add(_FactView(fact: fact));
      } else if (left == null) {
        left = fact;
      } else {
        addRow(left, fact);
        left = null;
      }
    }
    if (left != null) addRow(left, null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space4),
          rows[i],
        ],
      ],
    );
  }
}

class _FactView extends StatelessWidget {
  const _FactView({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final warn = AppStatusColors.of(
      context,
    ).tone(AppStatusTone.orange).foreground;
    return Semantics(
      container: true,
      label:
          '${fact.label}: ${fact.value}${fact.attention ? ', cần chú ý' : ''}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.label,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fact.attention) ...[
                Icon(
                  AppIcons.alertCircle,
                  size: AppSizes.iconInline,
                  color: warn,
                ),
                const SizedBox(width: AppSpacing.space1),
              ],
              Expanded(
                child: Text(
                  fact.value,
                  style: textTheme.titleSmall?.copyWith(
                    color: fact.attention ? warn : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

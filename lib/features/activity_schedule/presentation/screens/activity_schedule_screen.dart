import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_timeline.dart';
import 'package:carenest_app/features/activity_schedule/data/fake_activity_schedule_source.dart';
import 'package:carenest_app/features/activity_schedule/domain/activity_schedule.dart';
import 'package:carenest_app/features/class_roster/data/fake_class_roster_source.dart';

/// Lịch hoạt động — mockup T10, bỏ phần duyệt/ký giáo án (OBS-08, plan K3).
class ActivityScheduleScreen extends StatefulWidget {
  const ActivityScheduleScreen({
    super.key,
    required this.initialDay,
    required this.onReviewToday,
    this.classId = FakeClassRosterSource.classId,
    this.source = const FakeActivityScheduleSource(),
  });

  final DateTime initialDay;
  final VoidCallback onReviewToday;
  final String classId;
  final ActivityScheduleSource source;

  @override
  State<ActivityScheduleScreen> createState() => _ActivityScheduleScreenState();
}

class _ActivityScheduleScreenState extends State<ActivityScheduleScreen> {
  late final Future<WeekSchedule> _week = widget.source.loadWeek(
    widget.classId,
  );
  late DateTime _selected = widget.initialDay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<WeekSchedule>(
      future: _week,
      builder: (context, snapshot) {
        final week = snapshot.data;
        final weekEnd = week?.weekStart.add(const Duration(days: 4));
        return Scaffold(
          appBar: AppBar(title: const Text('Lịch hoạt động')),
          body: week == null
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.pagePadding),
                  child: AppSkeletonList(rows: 5),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    AppDayStrip(
                      days: [
                        for (var i = 0; i < 5; i++)
                          week.weekStart.add(Duration(days: i)),
                      ],
                      selected: _selected,
                      onChanged: (value) => setState(() => _selected = value),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppCard(
                      dense: true,
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.review,
                            size: AppSizes.iconTile,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Text(
                              'Kế hoạch tuần ${week.weekStart.day}–${DateLabels.dayMonth(weekEnd!)} · Chủ đề “${week.theme}”',
                              style: textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    if (week.days[_selected.weekday] case final entries?)
                      AppTimeline(
                        entries: [
                          for (final entry in entries)
                            AppTimelineEntry(
                              time: entry.time,
                              title: entry.title,
                              subtitle: entry.detail,
                              isCurrent:
                                  entry.isCurrent &&
                                  DateUtils.isSameDay(
                                    _selected,
                                    widget.initialDay,
                                  ),
                            ),
                        ],
                      )
                    else
                      const AppEmptyState(
                        title: 'Chưa có lịch',
                        message: 'Ngày này chưa có hoạt động.',
                      ),
                  ],
                ),
          bottomNavigationBar: AppBottomDock(
            children: [
              AppButton(
                label: 'Đánh giá hoạt động hôm nay',
                expand: true,
                onPressed: widget.onReviewToday,
              ),
            ],
          ),
        );
      },
    );
  }
}

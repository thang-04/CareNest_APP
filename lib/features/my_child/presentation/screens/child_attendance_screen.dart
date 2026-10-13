import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_month_calendar.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/my_child/domain/my_child.dart';
import 'package:carenest_app/features/my_child/presentation/widgets/my_child_widgets.dart';

extension on AttendanceDayStatus {
  String get label => switch (this) {
    AttendanceDayStatus.present => 'Có mặt',
    AttendanceDayStatus.excused => 'Nghỉ có phép',
    AttendanceDayStatus.absent => 'Vắng',
  };

  AppStatusTone get tone => switch (this) {
    AttendanceDayStatus.present => AppStatusTone.green,
    AttendanceDayStatus.excused => AppStatusTone.blue,
    AttendanceDayStatus.absent => AppStatusTone.red,
  };
}

/// Điểm danh & bữa ăn theo tháng — mockup P10. Số đếm là BE trả (ATT-01, ATT-04).
class ChildAttendanceScreen extends StatefulWidget {
  const ChildAttendanceScreen({
    super.key,
    required this.childId,
    required this.initialDay,
    this.source = const FakeMyChildSource(),
  });

  final String childId;
  final DateTime initialDay;
  final MyChildSource source;

  @override
  State<ChildAttendanceScreen> createState() => _ChildAttendanceScreenState();
}

class _ChildAttendanceScreenState extends State<ChildAttendanceScreen> {
  late Future<AttendanceMonth> _month = widget.source.loadAttendance(
    widget.childId,
  );
  late DateTime _selected = widget.initialDay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm danh & bữa ăn')),
      body: FutureBuilder<AttendanceMonth>(
        future: _month,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được điểm danh',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(
                  () => _month = widget.source.loadAttendance(widget.childId),
                ),
              ),
            );
          }
          final month = snapshot.data;
          if (month == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            );
          }
          final selectedDay = month.days
              .where((day) => DateUtils.isSameDay(day.date, _selected))
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppCard(
                dense: true,
                child: Text(
                  DateLabels.month(month.month),
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppStatRow(
                tiles: [
                  AppStatTile(
                    value: '${month.presentCount}',
                    label: 'Có mặt',
                    tone: AppStatusTone.green,
                  ),
                  AppStatTile(
                    value: '${month.excusedCount}',
                    label: 'Có phép',
                    tone: AppStatusTone.blue,
                  ),
                  AppStatTile(
                    value: '${month.absentCount}',
                    label: 'Vắng',
                    tone: AppStatusTone.red,
                  ),
                  AppStatTile(
                    value: '${month.cancelledMealCount}',
                    label: 'Suất huỷ',
                    tone: AppStatusTone.gray,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                dense: true,
                child: Column(
                  children: [
                    AppMonthCalendar(
                      month: month.month,
                      selected: _selected,
                      markers: {
                        for (final day in month.days)
                          day.date.day: AppDayMarker(
                            tone: day.status.tone,
                            label: day.status.label,
                          ),
                      },
                      onSelected: (date) => setState(() => _selected = date),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    const _Legend(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppCard(
                dense: true,
                child: selectedDay == null
                    ? Text(
                        '${DateLabels.weekdayDate(_selected)}: chưa có dữ liệu điểm danh.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      )
                    : _DayDetail(day: selectedDay),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final status = AppStatusColors.of(context);
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary);
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.space1),
        Flexible(child: Text(label, style: textStyle)),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        spacing: AppSpacing.space3,
        runSpacing: AppSpacing.space1,
        children: [
          item(status.tone(AppStatusTone.green).main, 'Có mặt'),
          item(status.tone(AppStatusTone.blue).main, 'Nghỉ có phép'),
          item(status.tone(AppStatusTone.red).main, 'Vắng'),
          item(AppColors.textDisabled, 'Cuối tuần'),
        ],
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            Text(DateLabels.weekdayDate(day.date), style: textTheme.titleSmall),
            AppStatusBadge(label: day.status.label, tone: day.status.tone),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        if (day.arrivedAt case final arrived?)
          InfoLine(label: 'Đến lớp', value: DateLabels.time24(arrived)),
        if (day.mealsLine case final meals?)
          InfoLine(label: 'Bữa', value: meals),
        if (day.pickupLine case final pickup?)
          InfoLine(label: 'Đón về', value: pickup),
        if (day.mealCancelled)
          const InfoLine(label: 'Suất ăn', value: 'Đã huỷ theo đơn xin nghỉ'),
      ],
    );
  }
}

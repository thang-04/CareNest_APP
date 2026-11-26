import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';

/// Hoạt động trong ngày của lớp bé (EDU-37, user 26/11): tên các hoạt động trong giáo án ngày đã ban
/// hành, theo thứ tự dòng của bảng tuần; không giờ, không ảnh. Đổi ngày trong tuần bằng dải ngày.
class ChildActivitiesScreen extends StatefulWidget {
  const ChildActivitiesScreen({
    super.key,
    required this.childId,
    this.initialDay,
    this.source = const FakeMyChildSource(),
  });

  final String childId;

  /// Ngày mở đầu; null ⇒ hôm nay theo BE.
  final DateTime? initialDay;
  final MyChildSource source;

  @override
  State<ChildActivitiesScreen> createState() => _ChildActivitiesScreenState();
}

class _ChildActivitiesScreenState extends State<ChildActivitiesScreen> {
  late DateTime? _date = widget.initialDay;
  late Future<ActivityDay> _day = _load();

  Future<ActivityDay> _load() =>
      widget.source.loadActivities(widget.childId, date: _date);

  void _open(DateTime date) => setState(() {
    _date = date;
    _day = _load();
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hoạt động trong ngày')),
      body: FutureBuilder<ActivityDay>(
        future: _day,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được hoạt động',
                message: loadFailureMessage(snapshot.error),
                onRetry: () => setState(() => _day = _load()),
              ),
            );
          }
          final day = snapshot.data;
          if (day == null ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 4),
            );
          }
          final monday = mondayOf(day.date);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppDayStrip(
                days: [
                  for (var i = 0; i < 5; i++)
                    DateTime(monday.year, monday.month, monday.day + i),
                ],
                selected: day.date,
                onChanged: _open,
              ),
              const SizedBox(height: AppSpacing.space4),
              if (day.groups.isEmpty)
                const AppEmptyState(
                  icon: AppIcons.calendarOff,
                  title: 'Lớp chưa có giáo án ngày này',
                  message:
                      'Hoạt động hiện khi giáo án ngày của lớp đã được duyệt.',
                )
              else
                for (final group in day.groups) ...[
                  AppCard(
                    dense: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          group.label,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        for (final item in group.items) ...[
                          const SizedBox(height: AppSpacing.space1),
                          Text(item, style: textTheme.bodyLarge),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
            ],
          );
        },
      ),
    );
  }
}

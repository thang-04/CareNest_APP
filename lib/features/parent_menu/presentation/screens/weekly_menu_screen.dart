import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/parent_menu/data/fake_weekly_menu_source.dart';
import 'package:carenest_app/features/parent_menu/domain/weekly_menu.dart';

/// Thực đơn tuần của bé — mockup P05. Chỉ thực đơn đã công bố (NUT-08).
class WeeklyMenuScreen extends StatefulWidget {
  const WeeklyMenuScreen({
    super.key,
    required this.childId,
    required this.initialDay,
    this.source = const FakeWeeklyMenuSource(),
  });

  final String childId;
  final DateTime initialDay;
  final WeeklyMenuSource source;

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen> {
  late Future<WeeklyMenu> _week = widget.source.loadWeek(widget.childId);
  late DateTime _selected = widget.initialDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thực đơn tuần')),
      body: FutureBuilder<WeeklyMenu>(
        future: _week,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppErrorState(
                title: 'Chưa tải được thực đơn',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(
                  () => _week = widget.source.loadWeek(widget.childId),
                ),
              ),
            );
          }
          final week = snapshot.data;
          if (week == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 3),
            );
          }
          final day = week.days
              .where((item) => DateUtils.isSameDay(item.date, _selected))
              .firstOrNull;
          final weekEnd = week.weekStart.add(const Duration(days: 4));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppCard(
                dense: true,
                child: Text(
                  'Tuần ${DateLabels.dayMonth(week.weekStart)} – ${DateLabels.date(weekEnd)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AppDayStrip(
                days: [for (final item in week.days) item.date],
                selected: _selected,
                onChanged: (value) => setState(() => _selected = value),
              ),
              const SizedBox(height: AppSpacing.space4),
              if (day == null)
                const AppEmptyState(
                  icon: AppIcons.menuBook,
                  title: 'Chưa có thực đơn',
                  message: 'Nhà trường chưa công bố thực đơn ngày này.',
                )
              else
                ..._dayContent(context, day),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _dayContent(BuildContext context, MenuDay day) {
    final textTheme = Theme.of(context).textTheme;
    return [
      for (final meal in day.meals) ...[
        AppCard(
          dense: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.meal,
                size: AppSizes.iconTile,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meal.name} · ${meal.time}',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      meal.dishes,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      if (day.energyNote != null) ...[
        AppBanner(message: day.energyNote!),
        const SizedBox(height: AppSpacing.space3),
      ],
      if (day.allergyNote != null) ...[
        AppBanner(
          kind: day.allergyAlert
              ? AppBannerKind.warning
              : AppBannerKind.success,
          message: day.allergyNote!,
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      if (day.photos case final photos?)
        AppCard(
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Ảnh bữa ăn · ${DateLabels.weekdayDayMonth(day.date)}',
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    '${photos.postedBy} đăng ${DateLabels.time24(photos.postedAt)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < photos.slots.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: AppPhotoPlaceholder(caption: photos.slots[i]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
    ];
  }
}

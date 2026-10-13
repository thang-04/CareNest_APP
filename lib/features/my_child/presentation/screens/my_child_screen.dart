import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/my_child/data/fake_my_child_source.dart';
import 'package:carenest_app/features/my_child/domain/my_child.dart';
import 'package:carenest_app/features/my_child/presentation/widgets/my_child_widgets.dart';
import 'package:carenest_app/features/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent_home/presentation/selected_child.dart';
import 'package:carenest_app/features/parent_home/presentation/widgets/parent_home_cards.dart';
import 'package:carenest_app/routing/route_paths.dart';

enum MyChildTab { today, health, development }

/// Tab "Bé của tôi" — mockup P08 (Hôm nay), P11 (Sức khỏe), P12 (Phát triển).
class MyChildScreen extends StatefulWidget {
  const MyChildScreen({
    super.key,
    this.initialTab = MyChildTab.today,
    this.source = const FakeMyChildSource(),
  });

  final MyChildTab initialTab;
  final MyChildSource source;

  @override
  State<MyChildScreen> createState() => _MyChildScreenState();
}

class _MyChildScreenState extends State<MyChildScreen> {
  late MyChildTab _tab = widget.initialTab;

  @override
  void didUpdateWidget(MyChildScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mở tab từ lối tắt khác (vd. "Sức khỏe" ở Trang chủ) khi màn đã nằm trong nhánh tab
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<String>(
      valueListenable: SelectedChild.notifier,
      builder: (context, childId, _) {
        final child = FakeParentHomeSource.childById(childId);
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(
                    text: 'Bé của tôi',
                    children: [
                      TextSpan(
                        text: ' · ${child.fullName}',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  style: textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSegmented<MyChildTab>(
                segments: const [
                  (MyChildTab.today, 'Hôm nay'),
                  (MyChildTab.health, 'Sức khỏe'),
                  (MyChildTab.development, 'Phát triển'),
                ],
                selected: _tab,
                onChanged: (value) => setState(() => _tab = value),
              ),
              const SizedBox(height: AppSpacing.space4),
              switch (_tab) {
                MyChildTab.today => _TodayTab(
                  key: ValueKey('today-$childId'),
                  childId: childId,
                  source: widget.source,
                ),
                MyChildTab.health => _HealthTab(
                  key: ValueKey('health-$childId'),
                  childId: childId,
                  source: widget.source,
                ),
                MyChildTab.development => _DevelopmentTab(
                  key: ValueKey('development-$childId'),
                  childId: childId,
                  source: widget.source,
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

/// Tải một khối dữ liệu theo bé, hiện khung chờ / lỗi + Thử lại theo chuẩn chung.
class _Loader<T> extends StatefulWidget {
  const _Loader({required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<_Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<_Loader<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Chưa tải được thông tin của bé',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            onRetry: () => setState(() => _future = widget.load()),
          );
        }
        final data = snapshot.data;
        if (data == null) return const AppSkeletonList(rows: 3);
        return widget.builder(context, data);
      },
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({super.key, required this.childId, required this.source});

  final String childId;
  final MyChildSource source;

  static IconData _icon(DayEventKind kind) => switch (kind) {
    DayEventKind.attendance => AppIcons.checkCircle,
    DayEventKind.meal => AppIcons.meal,
    DayEventKind.activity => AppIcons.image,
    DayEventKind.pickup => AppIcons.walk,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    void push(String path) => context.push(RoutePaths.withChild(path, childId));
    return _Loader<ChildToday>(
      load: () => source.loadToday(childId),
      builder: (context, today) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                DateLabels.weekdayDate(today.date),
                style: textTheme.titleSmall,
              ),
              AppLinkButton(
                label: 'Xem chi tiết ›',
                onPressed: () => push(RoutePaths.parentActivities),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          AppCard(
            flush: true,
            child: AppDividedColumn(
              children: [
                for (final event in today.events)
                  AppListRow(
                    leading: Icon(
                      _icon(event.kind),
                      size: AppSizes.iconTile,
                      color: AppColors.primary,
                    ),
                    title: '${DateLabels.time24(event.time)} · ${event.label}',
                  ),
              ],
            ),
          ),
          if (today.review case final review?) ...[
            const SizedBox(height: AppSpacing.space3),
            AppCard(
              dense: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đánh giá của ${review.teacher}',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  ReviewTagWrap(tags: review.tags),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          UtilityGrid(
            items: [
              UtilityItem(
                AppIcons.calendar,
                'Lịch điểm danh',
                () => push(RoutePaths.parentAttendance),
              ),
              UtilityItem(
                AppIcons.childFace,
                'Hồ sơ của bé',
                () => push(RoutePaths.parentChildProfile),
              ),
            ],
          ),
          if (today.upcomingLeave case final leave?) ...[
            const SizedBox(height: AppSpacing.space3),
            AppCard(
              flush: true,
              child: AppListRow(
                leading: const Icon(
                  AppIcons.calendarOff,
                  size: AppSizes.iconTile,
                  color: AppColors.primary,
                ),
                title: leave.title,
                subtitle: Text(leave.detail),
                trailing: AppStatusBadge(
                  label: leave.seenByTeacher ? 'GV đã xem' : 'GV chưa xem',
                  tone: leave.seenByTeacher
                      ? AppStatusTone.green
                      : AppStatusTone.approval,
                ),
                onTap: () => push(RoutePaths.parentLeaveNotices),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthTab extends StatelessWidget {
  const _HealthTab({super.key, required this.childId, required this.source});

  final String childId;
  final MyChildSource source;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Loader<HealthSummary>(
      load: () => source.loadHealth(childId),
      builder: (context, health) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lần đo gần nhất · ${DateLabels.date(health.measuredOn)}',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.space3),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _MeasureBox('Chiều cao', health.height)),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(child: _MeasureBox('Cân nặng', health.weight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (health.nutritionLabel case final label?) ...[
            const SizedBox(height: AppSpacing.space3),
            AppCard(
              dense: true,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  Text('Tình trạng dinh dưỡng', style: textTheme.titleSmall),
                  AppStatusBadge(label: label, tone: AppStatusTone.green),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cân nặng ${health.weightTrend.length} tháng gần nhất (kg)',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.space3),
                WeightTrendChart(points: health.weightTrend),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            flush: true,
            child: AppListRow(
              leading: Icon(
                AppIcons.heart,
                size: AppSizes.iconTile,
                color: AppStatusColors.of(
                  context,
                ).feedbackOf(AppFeedback.danger).main,
              ),
              title: 'Dị ứng & chế độ ăn',
              subtitle: Text(health.dietLine),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Kết quả đo do giáo viên công bố, chỉ để theo dõi, không thay thế chẩn đoán y tế.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MeasureBox extends StatelessWidget {
  const _MeasureBox(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              value,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.onBrand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentTab extends StatelessWidget {
  const _DevelopmentTab({
    super.key,
    required this.childId,
    required this.source,
  });

  final String childId;
  final MyChildSource source;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return _Loader<DevelopmentSummary>(
      load: () => source.loadDevelopment(childId),
      builder: (context, dev) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    Text(
                      'Nhận xét tuần ${dev.weekRange}',
                      style: textTheme.titleSmall,
                    ),
                    if (dev.weekConfirmed)
                      const AppStatusBadge(
                        label: 'Đã xác nhận',
                        tone: AppStatusTone.green,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(dev.weekNote, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.space1),
                Text(dev.weekAuthor, style: muted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            flush: true,
            child: AppListRow(
              leading: const Icon(
                AppIcons.clipboardCheck,
                size: AppSizes.iconTile,
                color: AppColors.primary,
              ),
              title: dev.monthlyTitle,
              showChevron: true,
              onTap: () => openComingSoon(context, dev.monthlyTitle),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cờ · ${dev.flagMonth}', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  'Đã có ${dev.flagsEarned} phiếu tuần · cần ${dev.flagsNeeded} phiếu để nhận bé ngoan',
                  style: muted,
                ),
                const SizedBox(height: AppSpacing.space3),
                Semantics(
                  container: true,
                  label: '${dev.flagsEarned} trên ${dev.flagSlots} phiếu tuần',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      for (var i = 0; i < dev.flagSlots; i++)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.space3,
                          ),
                          child: Icon(
                            i < dev.flagsEarned
                                ? AppIcons.flag
                                : AppIcons.flagOutline,
                            size: 28,
                            color: i < dev.flagsEarned
                                ? AppColors.accentText
                                : AppColors.textDisabled,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  AppIcons.trophy,
                  size: AppSizes.iconTile,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khen thưởng cuối năm', style: textTheme.titleSmall),
                      Text(dev.yearEndNote, style: muted),
                    ],
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

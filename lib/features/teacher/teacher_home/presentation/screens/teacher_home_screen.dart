import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/parent/parent_home/presentation/widgets/parent_home_cards.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';
import 'package:carenest_app/features/teacher/teacher_home/data/fake_teacher_home_source.dart';
import 'package:carenest_app/features/teacher/teacher_home/domain/teacher_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Giáo viên · Trang chủ — cùng bố cục Trang chủ phụ huynh (user 24/11): lời chào + chuông →
/// thẻ lớp nổi với dải ba ô → Cần làm (Điểm danh → Sức khỏe → Trả trẻ) → lưới Việc nhanh.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key, this.source, this.onSwitchToParent});

  final TeacherHomeSource? source;

  /// Tài khoản GV kiêm phụ huynh (AUTH-21) ⇒ nút "Phụ huynh" chuyển chế độ; null ⇒ ẩn.
  final VoidCallback? onSwitchToParent;

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late final TeacherHomeSource _source =
      widget.source ?? FakeTeacherHomeSource();
  TeacherToday? _today;
  Object? _error;

  @override
  void initState() {
    super.initState();
    SelectedSchoolYear.notifier.addListener(_onYear);
    _load();
  }

  @override
  void dispose() {
    SelectedSchoolYear.notifier.removeListener(_onYear);
    super.dispose();
  }

  void _onYear() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final today = await _source.loadToday();
      if (mounted) setState(() => _today = today);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  static IconData _icon(TeacherTaskKind kind) => switch (kind) {
    TeacherTaskKind.attendance => AppIcons.clipboardCheck,
    TeacherTaskKind.leave => AppIcons.calendarOff,
    TeacherTaskKind.review => AppIcons.review,
    TeacherTaskKind.pickup => AppIcons.walk,
    TeacherTaskKind.menu => AppIcons.menuBook,
    TeacherTaskKind.rewards => AppIcons.trophy,
    TeacherTaskKind.health => AppIcons.heart,
    TeacherTaskKind.dailyHealth => AppIcons.sick,
  };

  // Cùng tông ô Việc nhanh của phụ huynh
  static AppStatusTone _gridTone(TeacherTaskKind kind) => switch (kind) {
    TeacherTaskKind.leave => AppStatusTone.orange,
    TeacherTaskKind.review => AppStatusTone.teal,
    TeacherTaskKind.menu => AppStatusTone.green,
    TeacherTaskKind.rewards => AppStatusTone.approval,
    TeacherTaskKind.health => AppStatusTone.red,
    _ => AppStatusTone.blue,
  };

  static String _path(TeacherTaskKind kind) => switch (kind) {
    TeacherTaskKind.attendance => RoutePaths.teacherAttendance,
    TeacherTaskKind.leave => RoutePaths.teacherLeaveNotices,
    TeacherTaskKind.review => RoutePaths.teacherReviews,
    TeacherTaskKind.pickup => RoutePaths.teacherPickup,
    TeacherTaskKind.menu => RoutePaths.teacherMenu,
    TeacherTaskKind.rewards => RoutePaths.teacherRewards,
    TeacherTaskKind.health => RoutePaths.teacherHealth,
    TeacherTaskKind.dailyHealth => RoutePaths.teacherDailyHealth,
  };

  static AppStatusTone _tone(TaskBadgeLevel level) => switch (level) {
    TaskBadgeLevel.todo => AppStatusTone.approval,
    TaskBadgeLevel.fresh => AppStatusTone.blue,
    TaskBadgeLevel.info => AppStatusTone.gray,
  };

  static bool _isAction(TeacherTaskKind kind) => switch (kind) {
    TeacherTaskKind.attendance ||
    TeacherTaskKind.dailyHealth ||
    TeacherTaskKind.pickup => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final today = _today;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          topInset + AppSpacing.pagePadding,
          AppSpacing.pagePadding,
          AppSpacing.sectionGap,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào cô,',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        today?.teacherName ?? '',
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                container: true,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.buttonSecondary,
                  ),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: AppColors.textPrimary),
                    child: AppHeroBell(
                      unread: 0,
                      onPressed: () =>
                          context.go(RoutePaths.teacherNotifications),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              const Expanded(child: SchoolYearChip()),
              if (widget.onSwitchToParent case final onSwitch?)
                AppFilterChip(
                  label: 'Phụ huynh',
                  icon: AppIcons.childFace,
                  selected: false,
                  onSelected: onSwitch,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          ..._buildBody(today),
        ],
      ),
    );
  }

  List<Widget> _buildBody(TeacherToday? today) {
    if (_error != null) {
      return [
        AppErrorState(
          title: 'Chưa tải được việc hôm nay',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    if (today == null) {
      return const [
        AppSkeletonCard(lines: 4),
        SizedBox(height: AppSpacing.sectionGap),
        AppSkeletonList(rows: 3),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    final year = SelectedSchoolYear.value;
    // AUTH-03: năm đã đóng chỉ xem; việc theo ngày (điểm danh, sức khỏe, trả trẻ) chỉ ở năm đang chạy
    if (year.readOnly) {
      return [
        _ClassCard(
          className: year.className,
          subtitle: 'Năm học ${year.label}',
          today: null,
          deadline: null,
          onOpenAttendance: () {},
          onOpenSchedule: () {},
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Semantics(
          header: true,
          child: Text('Xem lại', style: textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.space3),
        UtilityGrid(
          items: [
            for (final task in today.tasks.where(
              (task) =>
                  !_isAction(task.kind) && task.kind != TeacherTaskKind.menu,
            ))
              UtilityItem(
                _icon(task.kind),
                task.title,
                () => context.push(_path(task.kind)),
                tone: _gridTone(task.kind),
              ),
          ],
        ),
      ];
    }
    final attendanceOpen = today.tasks.any(
      (task) => task.kind == TeacherTaskKind.attendance,
    );
    final actionTasks = today.tasks
        .where((task) => _isAction(task.kind))
        .toList();
    final viewTasks = today.tasks
        .where((task) => !_isAction(task.kind))
        .toList();
    return [
      _ClassCard(
        className: today.className,
        subtitle: '${today.childCount} bé',
        today: today,
        deadline: attendanceOpen ? today.deadlineNote : null,
        onOpenAttendance: () => context.push(RoutePaths.teacherAttendance),
        onOpenSchedule: () => context.push(RoutePaths.teacherSchedule),
      ),
      const SizedBox(height: AppSpacing.sectionGap),
      Semantics(
        header: true,
        child: Text('Cần làm', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (actionTasks.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không còn việc nào',
          message: 'Các việc trong ngày của lớp đã xong.',
        )
      else
        for (final task in actionTasks) ...[
          _TaskRow(
            task: task,
            icon: _icon(task.kind),
            tone: _tone(task.badgeLevel),
            onTap: () => context.push(_path(task.kind)),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
      const SizedBox(height: AppSpacing.space3),
      Semantics(
        header: true,
        child: Text('Việc nhanh', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      UtilityGrid(
        items: [
          for (final task in viewTasks)
            UtilityItem(
              _icon(task.kind),
              task.title,
              () => context.push(_path(task.kind)),
              tone: _gridTone(task.kind),
            ),
          UtilityItem(
            AppIcons.calendar,
            'Lịch hoạt động',
            () => context.push(RoutePaths.teacherSchedule),
            tone: AppStatusTone.blue,
          ),
        ],
      ),
    ];
  }
}

/// Thẻ lớp nổi như thẻ bé ở Trang chủ phụ huynh: lớp + sĩ số, hạn điểm danh (BE trả), dải ba ô.
class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.className,
    required this.subtitle,
    required this.today,
    required this.deadline,
    required this.onOpenAttendance,
    required this.onOpenSchedule,
  });

  final String className;
  final String subtitle;

  /// null ⇒ năm học cũ, không có dải việc hôm nay.
  final TeacherToday? today;
  final String? deadline;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = this.today;
    return AppFeaturedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppIconTile(icon: AppIcons.classGroup),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(className, style: textTheme.headlineSmall),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (deadline != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(
                label: deadline!,
                tone: AppStatusTone.orange,
                icon: AppIcons.clock,
              ),
            ),
          ],
          if (today != null) ...[
            const SizedBox(height: AppSpacing.space4),
            _Strip(
              cells: [
                (
                  'Điểm danh',
                  // Số đã điểm danh do BE trả; null ⇒ chỉ nhãn
                  today.attendanceRecorded == null
                      ? '—'
                      : '${today.attendanceRecorded}/${today.childCount}',
                  onOpenAttendance,
                ),
                (
                  'Hoạt động',
                  today.currentActivity ?? 'Chưa có',
                  onOpenSchedule,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Dải ô như thẻ bé của phụ huynh; chữ lớn ⇒ xếp dọc.
class _Strip extends StatelessWidget {
  const _Strip({required this.cells});

  final List<(String, String, VoidCallback)> cells;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final items = [
      for (final (label, value, onTap) in cells)
        _StripItem(label: label, value: value, onTap: onTap),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(),
                  items[i],
                ],
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const VerticalDivider(width: 1),
                    Expanded(child: items[i]),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StripItem extends StatelessWidget {
  const _StripItem({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Việc cần làm: thẻ trắng nổi như ô Việc nhanh; việc đầu viền xanh.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final TeacherTask task;
  final IconData icon;
  final AppStatusTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Semantics(
      container: true,
      button: true,
      label: '${task.title}, ${task.subtitle}, ${task.badge}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: task.highlighted
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingDense),
              child: Row(
                children: [
                  AppIconTile(icon: icon),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: textTheme.titleSmall),
                        Text(
                          task.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (stacked) ...[
                          const SizedBox(height: AppSpacing.space1),
                          AppStatusBadge(label: task.badge, tone: tone),
                        ],
                      ],
                    ),
                  ),
                  if (!stacked) ...[
                    const SizedBox(width: AppSpacing.space2),
                    AppStatusBadge(label: task.badge, tone: tone),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

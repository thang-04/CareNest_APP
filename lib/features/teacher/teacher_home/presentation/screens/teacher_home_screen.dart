import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher/teacher_home/data/fake_teacher_home_source.dart';
import 'package:carenest_app/features/teacher/teacher_home/domain/teacher_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Giáo viên · Trang chủ theo Figma T01: dải xanh lời chào → thẻ lớp + Hoạt động hôm nay → hạn điểm danh → Việc cần làm hôm nay.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key, this.source});

  final TeacherHomeSource? source;

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
    _load();
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
    TeacherTaskKind.health => AppIcons.heart,
    TeacherTaskKind.dailyHealth => AppIcons.sick,
  };

  static String _path(TeacherTaskKind kind) => switch (kind) {
    TeacherTaskKind.attendance => RoutePaths.teacherAttendance,
    TeacherTaskKind.leave => RoutePaths.teacherLeaveNotices,
    TeacherTaskKind.review => RoutePaths.teacherReviews,
    TeacherTaskKind.pickup => RoutePaths.teacherPickup,
    TeacherTaskKind.health => RoutePaths.teacherHealth,
    TeacherTaskKind.dailyHealth => RoutePaths.teacherDailyHealth,
  };

  static AppStatusTone _tone(TaskBadgeLevel level) => switch (level) {
    TaskBadgeLevel.todo => AppStatusTone.approval,
    TaskBadgeLevel.fresh => AppStatusTone.blue,
    TaskBadgeLevel.info => AppStatusTone.gray,
  };

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final headerForeground = theme.colorScheme.surface;
    final topInset = MediaQuery.paddingOf(context).top;
    const headerHeight = 150.0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Figma T01: dải xanh có lời chào, thẻ lớp nổi đè lên mép dưới
          Stack(
            children: [
              Container(
                height: topInset + headerHeight,
                color: AppColors.primary,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  topInset + AppSpacing.cardPadding,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      container: true,
                      header: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào cô,',
                            style: textTheme.bodyMedium?.copyWith(
                              color: headerForeground.withValues(alpha: 0.85),
                            ),
                          ),
                          Text(
                            today?.teacherName ?? '',
                            style: textTheme.titleMedium?.copyWith(
                              color: headerForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    if (today != null && _error == null)
                      _ClassCard(
                        today: today,
                        onOpenSchedule: () =>
                            context.push(RoutePaths.teacherSchedule),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.cardGap,
              AppSpacing.pagePadding,
              AppSpacing.sectionGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildBody(today),
            ),
          ),
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
        AppSkeletonCard(lines: 3),
        SizedBox(height: AppSpacing.sectionGap),
        AppSkeletonList(rows: 4),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    final attendanceOpen = today.tasks.any(
      (task) => task.kind == TeacherTaskKind.attendance,
    );
    final actionTasks = today.tasks
        .where(
          (task) =>
              task.kind != TeacherTaskKind.leave &&
              task.kind != TeacherTaskKind.review,
        )
        .toList();
    final viewTasks = today.tasks
        .where(
          (task) =>
              task.kind == TeacherTaskKind.leave ||
              task.kind == TeacherTaskKind.review,
        )
        .toList();
    return [
      if (today.deadlineNote != null && attendanceOpen) ...[
        _DeadlineBanner(text: today.deadlineNote!),
        const SizedBox(height: AppSpacing.sectionGap),
      ],
      Semantics(
        header: true,
        child: Text('Cần làm', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (today.tasks.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không còn việc nào',
          message: 'Các việc trong ngày của lớp đã xong.',
        )
      else ...[
        for (final task in actionTasks) ...[
          _TaskRow(
            task: task,
            icon: _icon(task.kind),
            tone: _tone(task.badgeLevel),
            onTap: () => context.push(_path(task.kind)),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
        if (viewTasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          Semantics(
            header: true,
            child: Text('Xem nhanh', style: textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.space3),
          for (final task in viewTasks) ...[
            _TaskRow(
              task: task,
              icon: _icon(task.kind),
              tone: _tone(task.badgeLevel),
              onTap: () => context.push(_path(task.kind)),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ],
      ],
    ];
  }
}

/// Thẻ lớp trắng (Figma T01): lớp + sĩ số, hoạt động đang diễn ra, ô Hoạt động hôm nay bên phải.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.today, required this.onOpenSchedule});

  final TeacherToday today;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activity = today.currentActivity;
    final recorded = today.attendanceRecorded;
    const radius = Radius.circular(AppRadius.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPaddingDense),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lớp ${today.className} · ${today.childCount} bé',
                      style: textTheme.titleSmall,
                    ),
                    if (activity != null)
                      Text(
                        'Đang diễn ra: $activity',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    // Số đã điểm danh do BE trả; null ⇒ không hiện
                    if (recorded != null)
                      Text(
                        '$recorded/${today.childCount} đã điểm danh',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Ô cố định chiều rộng để cột thông tin lớp chiếm phần còn lại
            SizedBox(
              width: 116,
              child: Material(
                color: AppColors.primarySoft,
                borderRadius: const BorderRadius.horizontal(right: radius),
                child: InkWell(
                  onTap: onOpenSchedule,
                  borderRadius: const BorderRadius.horizontal(right: radius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPaddingDense,
                    ),
                    child: Center(
                      child: Text(
                        'Hoạt động\nhôm nay ›',
                        textAlign: TextAlign.center,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dải cảnh báo cam: hạn điểm danh do BE trả (ATT-06), APP không tự đếm giờ.
class _DeadlineBanner extends StatelessWidget {
  const _DeadlineBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingDense,
        vertical: AppSpacing.cardGap,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.clock, color: AppColors.warningText, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              text,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.warningText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một việc trong danh sách dọc (Figma T01): ô icon, tên, mô tả, badge; việc cần làm ngay viền xanh.
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
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: task.highlighted ? AppColors.primary : AppColors.border,
            width: task.highlighted ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPaddingDense,
              vertical: AppSpacing.cardGap,
            ),
            child: Row(
              children: [
                AppIconTile(icon: icon, tone: AppStatusTone.blue),
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
                      // Chữ lớn ⇒ badge xuống dòng thay vì ép tràn
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
    );
  }
}

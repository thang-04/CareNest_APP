import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_progress_ring.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/teacher_home/data/fake_teacher_home_source.dart';
import 'package:carenest_app/features/teacher_home/domain/teacher_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

//// Giáo viên · Trang chủ — bố cục D Clay: lời chào → thẻ lớp (vòng điểm danh, hạn, nút làm ngay) → Việc tiếp theo trượt ngang.
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
    TeacherTaskKind.mealPhotos => AppIcons.camera,
  };

  static String _path(TeacherTaskKind kind) => switch (kind) {
    TeacherTaskKind.attendance => RoutePaths.teacherAttendance,
    TeacherTaskKind.leave => RoutePaths.teacherLeaveNotices,
    TeacherTaskKind.review => RoutePaths.teacherReviews,
    TeacherTaskKind.pickup => RoutePaths.teacherPickup,
    TeacherTaskKind.health => RoutePaths.teacherHealth,
    TeacherTaskKind.mealPhotos => RoutePaths.teacherMealPhotos,
  };

  static AppStatusTone _tone(TaskBadgeLevel level) => switch (level) {
    TaskBadgeLevel.todo => AppStatusTone.approval,
    TaskBadgeLevel.fresh => AppStatusTone.blue,
    TaskBadgeLevel.info => AppStatusTone.gray,
  };

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          topInset + AppSpacing.space4,
          AppSpacing.pagePadding,
          AppSpacing.space6,
        ),
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
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  today?.teacherName ?? '',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
    final attendanceTask = today.tasks
        .where((task) => task.kind == TeacherTaskKind.attendance)
        .firstOrNull;
    final others = today.tasks
        .where((task) => task.kind != TeacherTaskKind.attendance)
        .toList();
    return [
      _ClassCard(
        today: today,
        onAttendance: attendanceTask == null
            ? null
            : () => context.push(RoutePaths.teacherAttendance),
        onOpenSchedule: () => context.push(RoutePaths.teacherSchedule),
      ),
      const SizedBox(height: AppSpacing.sectionGap),
      Semantics(
        header: true,
        child: Text('Việc tiếp theo', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (today.tasks.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không còn việc nào',
          message: 'Các việc trong ngày của lớp đã xong.',
        )
      else
        // Dựng đủ mọi thẻ (ít việc) để thẻ cao bằng nhau và trình đọc màn hình đọc được hết
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < others.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.space3),
                  _TaskTile(
                    task: others[i],
                    icon: _icon(others[i].kind),
                    tone: _tone(others[i].badgeLevel),
                    onTap: () => context.push(_path(others[i].kind)),
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }
}

/// Thẻ lớp nổi bật: tên lớp, sĩ số, hoạt động đang diễn ra, hạn điểm danh, vòng tiến độ, nút làm ngay.
class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.today,
    required this.onAttendance,
    required this.onOpenSchedule,
  });

  final TeacherToday today;

  /// Null khi không còn việc điểm danh hôm nay.
  final VoidCallback? onAttendance;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final recorded = today.attendanceRecorded;
    final orange = AppStatusColors.of(context).tone(AppStatusTone.orange);
    final activity = today.currentActivity;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lớp ${today.className}', style: textTheme.headlineSmall),
        Text(
          activity == null
              ? '${today.childCount} bé'
              : '${today.childCount} bé · Đang diễn ra: $activity',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
    final ring = recorded == null || today.childCount == 0
        ? null
        : AppProgressRing(
            value: recorded / today.childCount,
            label: '$recorded/${today.childCount}',
            caption: 'đã điểm danh',
            color: onAttendance == null ? null : orange.main,
          );
    // Chữ phóng lớn ⇒ vòng xuống dưới thông tin lớp thay vì ép cột chữ
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return AppFeaturedCard(
      tint: onAttendance == null ? null : orange.main,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stacked || ring == null) ...[
            info,
            if (ring != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Align(alignment: Alignment.centerLeft, child: ring),
            ],
          ] else
            Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: AppSpacing.space3),
                ring,
              ],
            ),
          if (today.deadlineNote != null && onAttendance != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(
                label: today.deadlineNote!,
                tone: AppStatusTone.orange,
                icon: AppIcons.clock,
              ),
            ),
          ],
          if (onAttendance != null) ...[
            const SizedBox(height: AppSpacing.space4),
            AppButton(
              label: 'Điểm danh ngay',
              icon: AppIcons.clipboardCheck,
              expand: true,
              onPressed: onAttendance,
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: AppLinkButton(
              label: 'Lịch hoạt động ›',
              onPressed: onOpenSchedule,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ việc trong dải trượt ngang: ô icon + badge, tên, mô tả.
class _TaskTile extends StatelessWidget {
  const _TaskTile({
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
    return SizedBox(
      width: 196,
      child: Semantics(
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconTile(icon: icon, tone: tone),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AppStatusBadge(
                              label: task.badge,
                              tone: tone,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(task.title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      task.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

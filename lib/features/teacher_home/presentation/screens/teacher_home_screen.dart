import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/teacher_home/data/fake_teacher_home_source.dart';
import 'package:carenest_app/features/teacher_home/domain/teacher_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Giáo viên · Trang chủ — Figma GV01 (bản sửa): dải chào, thẻ lớp + Lịch hoạt động, hạn điểm danh,
/// danh sách "Việc cần làm hôm nay".
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
    TeacherTaskKind.health => AppIcons.checkCircle,
  };

  static String _path(TeacherTaskKind kind) => switch (kind) {
    TeacherTaskKind.attendance => RoutePaths.teacherAttendance,
    TeacherTaskKind.leave => RoutePaths.teacherLeaveNotices,
    TeacherTaskKind.review => RoutePaths.teacherReviews,
    TeacherTaskKind.pickup => RoutePaths.teacherPickup,
    TeacherTaskKind.health => RoutePaths.teacherHealth,
  };

  static AppStatusTone _tone(TaskBadgeLevel level) => switch (level) {
    TaskBadgeLevel.todo => AppStatusTone.orange,
    TaskBadgeLevel.fresh => AppStatusTone.blue,
    TaskBadgeLevel.info => AppStatusTone.gray,
  };

  @override
  Widget build(BuildContext context) {
    final today = _today;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.space6),
        children: [
          AppHeroHeader(
            greeting: 'Chào cô,',
            name: today?.teacherName ?? '',
            card: today == null || _error != null
                ? null
                : _ClassCard(
                    today: today,
                    onOpenSchedule: () =>
                        context.push(RoutePaths.teacherSchedule),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.space3,
              AppSpacing.pagePadding,
              0,
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
        AppSkeletonCard(lines: 2),
        SizedBox(height: AppSpacing.sectionGap),
        AppSkeletonList(rows: 4),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    final attendancePending = today.tasks.any(
      (task) => task.kind == TeacherTaskKind.attendance,
    );
    final recorded = today.attendanceRecorded;
    return [
      if (attendancePending && today.deadlineNote != null)
        AppBanner(
          kind: AppBannerKind.warning,
          icon: AppIcons.clock,
          message: today.deadlineNote!,
        )
      // Hết việc điểm danh ⇒ báo số BE trả, APP không tự đếm
      else if (!attendancePending && recorded != null)
        AppBanner(
          kind: AppBannerKind.success,
          message: 'Đã điểm danh $recorded/${today.childCount} bé hôm nay.',
        ),
      const SizedBox(height: AppSpacing.space5),
      Semantics(
        header: true,
        child: Text('Việc cần làm hôm nay', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (today.tasks.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không còn việc nào',
          message: 'Các việc trong ngày của lớp đã xong.',
        )
      else
        for (final task in today.tasks) ...[
          AppTaskCard(
            icon: _icon(task.kind),
            title: task.title,
            subtitle: task.subtitle,
            highlighted: task.highlighted,
            trailing: AppStatusBadge(
              label: task.badge,
              tone: _tone(task.badgeLevel),
            ),
            onTap: () => context.push(_path(task.kind)),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
    ];
  }
}

/// Thẻ lớp đè mép dải chào: tên lớp, sĩ số, hoạt động đang diễn ra; ô phải mở Lịch hoạt động.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.today, required this.onOpenSchedule});

  final TeacherToday today;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activity = today.currentActivity;
    final info = Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lớp ${today.className} · ${today.childCount} bé',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (activity != null)
            Text(
              'Đang diễn ra: $activity',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
    final schedule = Semantics(
      container: true,
      button: true,
      label: 'Lịch hoạt động',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primarySoft,
        child: InkWell(
          onTap: onOpenSchedule,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minimumTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space3,
              ),
              child: Center(
                child: Text(
                  'Lịch hoạt động ›',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Chữ phóng lớn ⇒ ô Lịch hoạt động xuống dưới thay vì ép cột thông tin lớp
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, schedule],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: info),
                  Expanded(flex: 2, child: schedule),
                ],
              ),
            ),
    );
  }
}

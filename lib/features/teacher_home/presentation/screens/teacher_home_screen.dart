import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/teacher_home/data/fake_teacher_home_source.dart';
import 'package:carenest_app/features/teacher_home/domain/teacher_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Giáo viên · Trang chủ — mockup T01: hero + thẻ lớp → hạn điểm danh → Việc cần làm hôm nay.
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeroHeader(
            greeting: 'Chào cô,',
            name: today?.teacherName ?? '',
            // Lỗi tải ⇒ bỏ khung chờ ở thẻ lớp, lỗi hiện ở thân màn
            card: today == null
                ? (_error == null ? const AppSkeletonCard(lines: 1) : null)
                : _ClassCard(
                    today: today,
                    onOpenSchedule: () =>
                        context.push(RoutePaths.teacherSchedule),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.space5,
              AppSpacing.pagePadding,
              AppSpacing.space6,
            ),
            child: _buildBody(today),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TeacherToday? today) {
    if (_error != null) {
      return AppErrorState(
        title: 'Chưa tải được việc hôm nay',
        message: 'Kiểm tra kết nối mạng rồi thử lại.',
        onRetry: _load,
      );
    }
    if (today == null) return const AppSkeletonList(rows: 4);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (today.deadlineNote != null) ...[
          AppBanner(
            kind: AppBannerKind.warning,
            icon: AppIcons.clock,
            message: today.deadlineNote!,
          ),
          const SizedBox(height: AppSpacing.space5),
        ],
        Semantics(
          header: true,
          child: Text('Việc cần làm hôm nay', style: textTheme.titleSmall),
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
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.today, required this.onOpenSchedule});

  final TeacherToday today;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lớp ${today.className} · ${today.childCount} bé',
          style: textTheme.titleSmall,
        ),
        if (today.currentActivity != null)
          Text(
            'Đang diễn ra: ${today.currentActivity}',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
    final scheduleButton = Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onOpenSchedule,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space3,
          ),
          child: Text(
            'Lịch hoạt động ›',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
    // Chữ phóng lớn ⇒ nút lịch xuống dòng thay vì ép tràn
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return AppCard(
      dense: true,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AppSpacing.space2),
                scheduleButton,
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: AppSpacing.space2),
                scheduleButton,
              ],
            ),
    );
  }
}

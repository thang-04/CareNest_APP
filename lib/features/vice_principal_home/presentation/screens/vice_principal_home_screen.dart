import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';
import 'package:carenest_app/features/vice_principal_home/data/fake_campus_today_source.dart';
import 'package:carenest_app/features/vice_principal_home/domain/campus_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Phó HT · Trang chủ cơ sở (bố cục F): mốc giờ buổi sáng → chờ duyệt → theo dõi khác.
/// Chỉ cơ sở được phân công (AUTH-02); mốc, trạng thái và số do BE trả (AUTH-08).
class VicePrincipalHomeScreen extends StatefulWidget {
  const VicePrincipalHomeScreen({super.key, this.source, this.cookingSource});

  final CampusTodaySource? source;
  final CookingStatusSource? cookingSource;

  @override
  State<VicePrincipalHomeScreen> createState() =>
      _VicePrincipalHomeScreenState();
}

class _VicePrincipalHomeScreenState extends State<VicePrincipalHomeScreen> {
  late final CampusTodaySource _source =
      widget.source ?? FakeCampusTodaySource();
  late final CookingStatusSource _cooking =
      widget.cookingSource ?? FakeCookingStatusSource.shared;
  CampusToday? _today;
  MealCooking? _lunch;
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
      final cooking = await _cooking.loadToday();
      if (!mounted) return;
      setState(() {
        _today = today;
        _lunch = cooking[MealSlot.lunch];
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  // Quay lại từ màn con (đã chốt suất, đã duyệt) ⇒ tải lại để mốc và badge đúng
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) _load();
  }

  static IconData _icon(CampusTaskKind kind) => switch (kind) {
    CampusTaskKind.confirmMeals => AppIcons.meal,
    CampusTaskKind.approvals => AppIcons.approval,
    CampusTaskKind.kitchen => AppIcons.kitchen,
    CampusTaskKind.menu => AppIcons.menuBook,
    CampusTaskKind.children => AppIcons.childFace,
  };

  static AppStatusTone _tone(CampusBadgeLevel level) => switch (level) {
    CampusBadgeLevel.todo => AppStatusTone.orange,
    CampusBadgeLevel.fresh => AppStatusTone.blue,
    CampusBadgeLevel.watch => AppStatusTone.teal,
    CampusBadgeLevel.done => AppStatusTone.green,
    CampusBadgeLevel.view => AppStatusTone.blue,
  };

  void _openTask(CampusTaskKind kind) => switch (kind) {
    CampusTaskKind.confirmMeals => _open(RoutePaths.vicePrincipalMealConfirm),
    // Duyệt là một tab ⇒ chuyển tab, không chồng màn
    CampusTaskKind.approvals => context.go(RoutePaths.vicePrincipalApprovals),
    CampusTaskKind.kitchen => _open(RoutePaths.vicePrincipalKitchen),
    CampusTaskKind.menu => _open(RoutePaths.vicePrincipalMenu),
    CampusTaskKind.children => _open(RoutePaths.vicePrincipalChildren),
  };

  void _openPending(CampusPendingItem item) => switch (item.kind) {
    CampusPendingKind.mealAdjustment when item.id != null => _open(
      RoutePaths.vicePrincipalAdjustment(item.id!),
    ),
    CampusPendingKind.mealAdjustment => context.go(
      RoutePaths.vicePrincipalApprovals,
    ),
    CampusPendingKind.rewards => _open(RoutePaths.vicePrincipalRewards),
  };

  String _subtitle(CampusTask task) {
    final lunch = _lunch;
    if (task.kind != CampusTaskKind.kitchen || lunch == null) {
      return task.subtitle;
    }
    return '${task.subtitle}: ${lunch.stage.label}';
  }

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
                  'Sáng nay',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (today != null)
                  Text(
                    '${today.campusName} · ${DateLabels.weekdayDayMonth(today.date)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
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

  List<Widget> _buildBody(CampusToday? today) {
    if (_error != null) {
      return [
        AppErrorState(
          title: 'Chưa tải được số liệu cơ sở',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    if (today == null) {
      return const [
        AppSkeletonCard(lines: 5),
        SizedBox(height: AppSpacing.sectionGap),
        AppSkeletonList(rows: 3),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    // Chốt suất và duyệt đã có ở thẻ mốc và mục chờ duyệt ⇒ không lặp trong "Theo dõi khác"
    final others = today.tasks
        .where(
          (task) =>
              task.kind != CampusTaskKind.confirmMeals &&
              task.kind != CampusTaskKind.approvals,
        )
        .toList();
    return [
      if (today.morning.isNotEmpty) ...[
        _MorningCard(
          steps: today.morning,
          onConfirm: () => _open(RoutePaths.vicePrincipalMealConfirm),
          onKitchen: () => _open(RoutePaths.vicePrincipalKitchen),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
      ],
      _SectionHeader(
        title: today.pending.isEmpty
            ? 'Chờ duyệt'
            : 'Chờ duyệt (${today.pendingApprovals})',
        onAll: () => context.go(RoutePaths.vicePrincipalApprovals),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (today.pending.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không có yêu cầu chờ duyệt',
          message: 'Yêu cầu mới từ giáo viên và bếp sẽ hiện ở đây.',
        )
      else
        for (final item in today.pending) ...[
          AppTaskCard(
            icon: item.kind == CampusPendingKind.rewards
                ? AppIcons.trophy
                : AppIcons.meal,
            title: item.title,
            subtitle: item.note,
            // Cùng màu nhãn với tab Duyệt: suất ăn xanh, khen thưởng vàng
            trailing: item.kind == CampusPendingKind.rewards
                ? const AppStatusBadge(
                    label: 'Khen thưởng',
                    tone: AppStatusTone.approval,
                  )
                : const AppStatusBadge(
                    label: 'Suất ăn',
                    tone: AppStatusTone.blue,
                  ),
            onTap: () => _openPending(item),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
      if (others.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sectionGap - AppSpacing.space2),
        Semantics(
          header: true,
          child: Text('Theo dõi khác', style: textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.space3),
        for (final task in others) ...[
          AppTaskCard(
            icon: _icon(task.kind),
            title: task.title,
            subtitle: _subtitle(task),
            highlighted: task.highlighted,
            trailing: AppStatusBadge(
              label: task.badge,
              tone: _tone(task.level),
            ),
            onTap: () => _openTask(task.kind),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
      ],
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAll});

  final String title;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: textTheme.titleMedium),
          ),
        ),
        AppLinkButton(label: 'Tất cả', onPressed: onAll),
      ],
    );
  }
}

/// Thẻ mốc buổi sáng: cột giờ, đường ray, tên + ghi chú; mốc đang chờ nổi lên, chốt suất có nút làm ngay.
class _MorningCard extends StatelessWidget {
  const _MorningCard({
    required this.steps,
    required this.onConfirm,
    required this.onKitchen,
  });

  final List<MorningStep> steps;
  final VoidCallback onConfirm;
  final VoidCallback onKitchen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, step) in steps.indexed)
            _MorningRow(
              step: step,
              last: i == steps.length - 1,
              onAction: switch (step.kind) {
                MorningStepKind.mealConfirm
                    when step.state == MorningStepState.current =>
                  onConfirm,
                MorningStepKind.lunch
                    when step.state == MorningStepState.current =>
                  onKitchen,
                _ => null,
              },
            ),
        ],
      ),
    );
  }
}

class _MorningRow extends StatelessWidget {
  const _MorningRow({
    required this.step,
    required this.last,
    required this.onAction,
  });

  final MorningStep step;
  final bool last;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final green = status.tone(AppStatusTone.green);
    final orange = status.tone(AppStatusTone.orange);
    final done = step.state == MorningStepState.done;
    final current = step.state == MorningStepState.current;
    final confirm = step.kind == MorningStepKind.mealConfirm;
    final time = DateLabels.time24(step.time);
    final stateText = switch (step.state) {
      MorningStepState.done => 'đã xong',
      MorningStepState.current => confirm ? 'cần làm' : 'đang diễn ra',
      MorningStepState.upcoming => 'chưa tới',
    };
    final badge = switch (step.state) {
      MorningStepState.done => const AppStatusBadge(
        label: 'Xong',
        tone: AppStatusTone.green,
        icon: AppIcons.check,
      ),
      MorningStepState.current when confirm => const AppStatusBadge(
        label: 'Cần làm',
        tone: AppStatusTone.orange,
        icon: AppIcons.clock,
      ),
      MorningStepState.current => const AppStatusBadge(
        label: 'Đang diễn ra',
        tone: AppStatusTone.blue,
      ),
      MorningStepState.upcoming => null,
    };
    // Chữ phóng lớn ⇒ giờ lên đầu phần nội dung thay vì chiếm một cột
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final timeText = Text(
      time,
      maxLines: 1,
      softWrap: false,
      style: textTheme.labelLarge?.copyWith(
        color: current ? AppColors.textPrimary : AppColors.textMuted,
        fontWeight: current ? FontWeight.w700 : FontWeight.w500,
        fontFeatures: AppTextStyles.tabularFigures,
      ),
    );
    final dotColor = done
        ? green.main
        : current
        ? (confirm ? orange.main : AppColors.brand)
        : AppColors.track;
    final rail = SizedBox(
      width: 24,
      child: Column(
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.25),
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: done
                ? const Icon(AppIcons.check, size: 12, color: AppColors.surface)
                : null,
          ),
          if (!last)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
                color: done ? green.main : AppColors.track,
              ),
            ),
        ],
      ),
    );
    final note = step.note;
    return Semantics(
      container: true,
      label: [time, step.title, ?note, stateText].join(', '),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!large) ...[
              SizedBox(
                width: 52,
                child: ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: timeText,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
            ],
            ExcludeSemantics(child: rail),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (large) timeText,
                          Wrap(
                            spacing: AppSpacing.space2,
                            runSpacing: AppSpacing.space1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                step.title,
                                style: textTheme.titleSmall?.copyWith(
                                  color: step.state == MorningStepState.upcoming
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                ),
                              ),
                              ?badge,
                            ],
                          ),
                          if (note != null)
                            Text(
                              note,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (onAction != null) ...[
                      const SizedBox(height: AppSpacing.space3),
                      AppButton(
                        label: confirm ? 'Xem & chốt' : 'Xem bếp',
                        expand: true,
                        variant: confirm
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        onPressed: onAction,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

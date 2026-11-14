import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/kitchen_home/data/fake_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Bếp · Trang chủ — Figma Bếp 01 (bản sửa): dải chào + thẻ bếp, số suất đã chốt, Việc của bếp hôm nay.
/// Không theo dõi trạng thái nấu (NUT-14 REMOVED).
class KitchenHomeScreen extends StatefulWidget {
  const KitchenHomeScreen({super.key, this.source});

  final KitchenHomeSource? source;

  @override
  State<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends State<KitchenHomeScreen> {
  late final KitchenHomeSource _source =
      widget.source ?? FakeKitchenHomeSource();
  KitchenToday? _today;
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
      if (!mounted) return;
      setState(() => _today = today);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  // Quay lại từ màn con (vd. đã ghi lưu mẫu) ⇒ tải lại để badge đúng
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) _load();
  }

  static IconData _icon(KitchenTaskKind kind) => switch (kind) {
    KitchenTaskKind.menu => AppIcons.meal,
    KitchenTaskKind.mealCounts => AppIcons.classGroup,
    KitchenTaskKind.quantities => AppIcons.review,
    KitchenTaskKind.mealSamples => AppIcons.camera,
    KitchenTaskKind.sampleLog => AppIcons.clipboardCheck,
  };

  static AppStatusTone _tone(KitchenBadgeLevel level) => switch (level) {
    KitchenBadgeLevel.todo => AppStatusTone.approval,
    KitchenBadgeLevel.changed => AppStatusTone.orange,
    KitchenBadgeLevel.done => AppStatusTone.green,
    KitchenBadgeLevel.info => AppStatusTone.blue,
  };

  void _openTask(KitchenTaskKind kind) => switch (kind) {
    // Thực đơn là một tab ⇒ chuyển tab, không chồng màn
    KitchenTaskKind.menu => context.go(RoutePaths.kitchenMenu),
    KitchenTaskKind.mealCounts => _open(RoutePaths.kitchenMeals),
    KitchenTaskKind.quantities => _open(RoutePaths.kitchenQuantities),
    KitchenTaskKind.mealSamples => _open(RoutePaths.kitchenMealSamples),
    KitchenTaskKind.sampleLog => _open(RoutePaths.kitchenSampleLog),
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
            greeting: 'Xin chào,',
            name: today?.staffName ?? '',
            card: today == null ? null : _KitchenCard(today: today),
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

  List<Widget> _buildBody(KitchenToday? today) {
    if (_error != null) {
      return [
        AppErrorState(
          title: 'Chưa tải được việc của bếp',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    if (today == null) {
      return const [
        AppSkeletonCard(lines: 3),
        SizedBox(height: AppSpacing.space5),
        AppSkeletonList(rows: 3),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    final tasks = today.tasks;
    return [
      _CountCard(today: today),
      const SizedBox(height: AppSpacing.space4),
      Semantics(
        header: true,
        child: Text(
          'Việc của bếp hôm nay',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: AppSpacing.space2 + 2),
      if (tasks.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Chưa có việc hôm nay',
          message: 'Hôm nay bếp không phục vụ hoặc chưa có số suất.',
        )
      else
        for (final (i, task) in tasks.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space2),
          AppTaskCard(
            icon: _icon(task.kind),
            title: task.title,
            subtitle: task.subtitle,
            highlighted: task.highlighted,
            trailing: AppStatusBadge(
              label: task.badge,
              tone: _tone(task.level),
            ),
            onTap: () => _openTask(task.kind),
          ),
        ],
    ];
  }
}

/// Card trắng lề trong 16×12 như Figma Bếp 01 (gọn hơn `AppCard` dense).
class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      flush: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: child,
      ),
    );
  }
}

/// Thẻ bếp đè lên dải chào: tên bếp + ngày.
class _KitchenCard extends StatelessWidget {
  const _KitchenCard({required this.today});

  final KitchenToday today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _CompactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(today.kitchenLabel, style: textTheme.titleSmall),
          Text(
            DateLabels.weekdayDate(today.date),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Thẻ số suất đã chốt: tổng chữ số lớn bên trái, thường / thay thế bên phải.
class _CountCard extends StatelessWidget {
  const _CountCard({required this.today});

  final KitchenToday today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teal = AppStatusColors.of(context).tone(AppStatusTone.teal);
    final total = today.total;
    final confirmedAt = today.confirmedAt;
    if (total == null || confirmedAt == null) {
      return _CompactCard(
        child: Text(
          'Chưa có số suất đã chốt hôm nay.',
          style: textTheme.titleSmall,
        ),
      );
    }
    final meal = today.mealLabel ?? 'Suất ăn';
    return Semantics(
      container: true,
      label:
          '$meal đã chốt lúc ${DateLabels.time24(confirmedAt)}: $total suất, ${today.regular} thường, ${today.alternative} thay thế',
      excludeSemantics: true,
      child: _CompactCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                'Suất ăn đã chốt lúc ${DateLabels.time24(confirmedAt)}',
                ?today.mealLabel,
              ].join(' · '),
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Số lớn không xuống dòng ⇒ thu nhỏ khi chữ phóng lớn vượt chỗ
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$total',
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 32,
                            height: 1.15,
                            color: AppColors.primary,
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          'suất',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Flexible(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (today.regular != null)
                        Text(
                          '${today.regular} thường',
                          textAlign: TextAlign.end,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      if (today.alternative != null)
                        Text(
                          '${today.alternative} thay thế',
                          textAlign: TextAlign.end,
                          style: textTheme.bodyMedium?.copyWith(
                            color: teal.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

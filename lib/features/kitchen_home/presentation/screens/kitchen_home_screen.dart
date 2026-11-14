import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/kitchen_home/data/fake_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Bếp · Trang chủ — bố cục D Clay: tên bếp → số suất chữ lớn đọc từ xa → Việc của bếp hôm nay.
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
    KitchenBadgeLevel.info => AppStatusTone.gray,
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
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final meal = today?.mealLabel;
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
                  today?.kitchenLabel ?? '',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (today != null)
                  Text(
                    [?meal, DateLabels.weekdayDate(today.date)].join(' · '),
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
        AppSkeletonCard(lines: 4),
        SizedBox(height: AppSpacing.sectionGap),
        AppSkeletonList(rows: 3),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    final tasks = today.tasks;
    return [
      _CountCard(today: today),
      const SizedBox(height: AppSpacing.sectionGap),
      Semantics(
        header: true,
        child: Text('Việc của bếp hôm nay', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (tasks.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Chưa có việc hôm nay',
          message: 'Hôm nay bếp không phục vụ hoặc chưa có số suất.',
        )
      else
        for (final task in tasks) ...[
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
          const SizedBox(height: AppSpacing.space2),
        ],
    ];
  }
}

/// Thẻ số suất đã chốt, chữ số rất lớn để đọc từ xa khi đang nấu (bố cục D).
class _CountCard extends StatelessWidget {
  const _CountCard({required this.today});

  final KitchenToday today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = today.total;
    final confirmedAt = today.confirmedAt;
    if (total == null || confirmedAt == null) {
      return AppFeaturedCard(
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
      child: AppFeaturedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$meal đã chốt · ${DateLabels.time24(confirmedAt)}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$total',
                    style: textTheme.displaySmall?.copyWith(
                      fontSize: 72,
                      height: 1.1,
                      color: AppColors.textPrimary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text('suất', style: textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                if (today.regular != null)
                  AppStatusBadge(
                    label: 'Thường ${today.regular}',
                    tone: AppStatusTone.gray,
                  ),
                if (today.alternative != null)
                  AppStatusBadge(
                    label: 'Thay thế ${today.alternative}',
                    tone: AppStatusTone.teal,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

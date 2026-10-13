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
import 'package:carenest_app/features/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/kitchen_home/data/fake_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Bếp · Trang chủ — mockup K01: hero + thẻ bếp → suất đã chốt → Việc của bếp hôm nay.
class KitchenHomeScreen extends StatefulWidget {
  const KitchenHomeScreen({super.key, this.source, this.cookingSource});

  final KitchenHomeSource? source;
  final CookingStatusSource? cookingSource;

  @override
  State<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends State<KitchenHomeScreen> {
  late final KitchenHomeSource _source =
      widget.source ?? FakeKitchenHomeSource();
  late final CookingStatusSource _cooking =
      widget.cookingSource ?? FakeCookingStatusSource.shared;
  KitchenToday? _today;
  CookingStage? _lunchStage;
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
        _lunchStage = cooking[MealSlot.lunch]?.stage;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  // Quay lại từ màn con (vd. đã chuyển bước nấu) ⇒ tải lại để badge đúng
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) _load();
  }

  static IconData _icon(KitchenTaskKind kind) => switch (kind) {
    KitchenTaskKind.menu => AppIcons.meal,
    KitchenTaskKind.mealCounts => AppIcons.classGroup,
    KitchenTaskKind.quantities => AppIcons.review,
    KitchenTaskKind.receipt => AppIcons.truck,
    KitchenTaskKind.cooking => AppIcons.meal,
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
    KitchenTaskKind.receipt => _open(RoutePaths.kitchenReceipts),
    KitchenTaskKind.cooking => _open(RoutePaths.kitchenCooking),
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
            name: today?.staffName ?? '',
            card: today == null
                ? (_error == null ? const AppSkeletonCard(lines: 1) : null)
                : _KitchenCard(today: today, stage: _lunchStage),
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

  Widget _buildBody(KitchenToday? today) {
    if (_error != null) {
      return AppErrorState(
        title: 'Chưa tải được việc của bếp',
        message: 'Kiểm tra kết nối mạng rồi thử lại.',
        onRetry: _load,
      );
    }
    if (today == null) return const AppSkeletonList(rows: 4);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConfirmedCard(today: today),
        const SizedBox(height: AppSpacing.sectionGap),
        Semantics(
          header: true,
          child: Text('Việc của bếp hôm nay', style: textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (today.tasks.isEmpty)
          const AppEmptyState(
            icon: AppIcons.checkCircle,
            title: 'Chưa có việc hôm nay',
            message: 'Hôm nay bếp không phục vụ hoặc chưa có số suất.',
          )
        else
          for (final task in today.tasks) ...[
            AppTaskCard(
              icon: _icon(task.kind),
              title: task.title,
              subtitle:
                  task.kind == KitchenTaskKind.cooking && _lunchStage != null
                  ? '${task.subtitle}: ${_lunchStage!.label}'
                  : task.subtitle,
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
    );
  }
}

class _KitchenCard extends StatelessWidget {
  const _KitchenCard({required this.today, required this.stage});

  final KitchenToday today;
  final CookingStage? stage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(today.kitchenLabel, style: textTheme.titleSmall),
              Text(
                DateLabels.weekdayDate(today.date),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (stage != null)
            AppStatusBadge(
              label: stage!.label,
              tone: stage == CookingStage.cooking
                  ? AppStatusTone.orange
                  : AppStatusTone.green,
            ),
        ],
      ),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.today});

  final KitchenToday today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = today.total;
    final confirmedAt = today.confirmedAt;
    if (total == null || confirmedAt == null) {
      return const AppCard(
        dense: true,
        child: Text('Chưa có số suất đã chốt hôm nay.'),
      );
    }
    final teal = AppStatusColors.of(context).tone(AppStatusTone.teal);
    return Semantics(
      container: true,
      label:
          'Suất ăn đã chốt lúc ${DateLabels.time24(confirmedAt)}, ${today.mealLabel}: $total suất, ${today.regular} thường, ${today.alternative} thay thế',
      excludeSemantics: true,
      child: AppCard(
        dense: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suất ăn đã chốt lúc ${DateLabels.time24(confirmedAt)} · ${today.mealLabel}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space2),
            // Wrap: chữ phóng lớn thì phần thường / thay thế xuống dòng
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpacing.space3,
              runSpacing: AppSpacing.space2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$total',
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Flexible(child: Text('suất', style: textTheme.bodyLarge)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${today.regular} thường',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${today.alternative} thay thế',
                      style: textTheme.bodyMedium?.copyWith(
                        color: teal.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

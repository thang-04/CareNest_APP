import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/shadows.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/data/fake_kitchen_home_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_home/domain/kitchen_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Bếp · Trang chủ theo BE `/nutrition/kitchen/day` (canvas "Trang chủ bếp (theo BE)", user 18/11):
/// số suất đã chốt từng bữa → Việc hôm nay (ảnh mẫu, lưu mẫu, hủy mẫu) → Xem nhanh.
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
    setState(() {
      _error = null;
    });
    try {
      final today = await _source.loadToday();
      if (!mounted) return;
      setState(() {
        _today = today;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
      });
    }
  }

  // Quay lại từ màn con (đã chụp ảnh, đã ghi mẫu) ⇒ tải lại để việc hôm nay đúng
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) _load();
  }

  static IconData _icon(KitchenTaskKind kind) => switch (kind) {
    KitchenTaskKind.mealPhotos => AppIcons.camera,
    KitchenTaskKind.foodSamples => AppIcons.clipboardCheck,
    KitchenTaskKind.sampleDisposal => AppIcons.clock,
  };

  static AppStatusTone _iconTone(KitchenTaskKind kind) => switch (kind) {
    KitchenTaskKind.mealPhotos => AppStatusTone.blue,
    KitchenTaskKind.foodSamples => AppStatusTone.green,
    KitchenTaskKind.sampleDisposal => AppStatusTone.gray,
  };

  // Tông "approval" chỉ dành cho chờ duyệt (DESIGN.md §3.2)
  static AppStatusTone _tone(KitchenTaskLevel level) => switch (level) {
    KitchenTaskLevel.todo => AppStatusTone.orange,
    KitchenTaskLevel.missed => AppStatusTone.red,
    KitchenTaskLevel.waiting => AppStatusTone.approval,
    KitchenTaskLevel.due => AppStatusTone.blue,
    KitchenTaskLevel.done => AppStatusTone.green,
    KitchenTaskLevel.later => AppStatusTone.gray,
  };

  void _openTask(KitchenTaskKind kind) => switch (kind) {
    KitchenTaskKind.mealPhotos => _open(RoutePaths.kitchenPhotos),
    KitchenTaskKind.foodSamples ||
    KitchenTaskKind.sampleDisposal => _open(RoutePaths.kitchenSamples),
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
                Text('Bếp hôm nay', style: textTheme.headlineSmall),
                if (today != null)
                  Text(
                    '${DateLabels.weekdayDayMonth(today.date)} · ${today.campusLabel}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
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
    return [
      if (today.isDayOff)
        const AppEmptyState(
          title: 'Hôm nay trường nghỉ',
          message: 'Bếp không nấu, không cần ảnh mẫu hay lưu mẫu.',
        )
      else ...[
        _CountCard(
          today: today,
          onOpenClasses: () => _open(RoutePaths.kitchenMeals),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Semantics(
          header: true,
          child: Text('Việc hôm nay', style: textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (today.tasks.isEmpty)
          const AppEmptyState(
            icon: AppIcons.checkCircle,
            title: 'Chưa có việc hôm nay',
            message: 'Việc ảnh mẫu và lưu mẫu hiện khi có thực đơn đã công bố.',
          )
        else
          for (final task in today.tasks) ...[
            AppTaskCard(
              icon: _icon(task.kind),
              tone: _iconTone(task.kind),
              title: task.title,
              subtitle: task.subtitle,
              trailing: AppStatusBadge(
                label: task.badge,
                tone: _tone(task.level),
              ),
              onTap: () => _openTask(task.kind),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
      ],
      const SizedBox(height: AppSpacing.sectionGap),
      Semantics(
        header: true,
        child: Text('Xem nhanh', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _QuickLink(
                icon: AppIcons.classGroup,
                label: 'Suất ăn theo lớp',
                onTap: () => _open(RoutePaths.kitchenMeals),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _QuickLink(
                icon: AppIcons.fish,
                label: 'Lượng thực phẩm',
                onTap: () => _open(RoutePaths.kitchenQuantities),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _QuickLink(
                icon: AppIcons.menuBook,
                label: 'Thực đơn tuần',
                // Thực đơn là một tab ⇒ chuyển tab, không chồng màn
                onTap: () => context.go(RoutePaths.kitchenMenu),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

/// Số suất đã xác nhận từng bữa (NUT-02): số lớn để đọc từ xa khi đang nấu, kèm số thay thế.
class _CountCard extends StatelessWidget {
  const _CountCard({required this.today, required this.onOpenClasses});

  final KitchenToday today;
  final VoidCallback onOpenClasses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final confirmedAt = today.confirmedAt;
    final hasCounts =
        today.countStatus != KitchenCountStatus.none &&
        today.servings.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              Semantics(
                header: true,
                child: Text('Số suất đã chốt', style: textTheme.titleMedium),
              ),
              if (hasCounts && confirmedAt != null)
                AppStatusBadge(
                  label: 'PHT xác nhận ${DateLabels.time24(confirmedAt)}',
                  tone: AppStatusTone.green,
                  icon: AppIcons.check,
                ),
            ],
          ),
          if (!hasCounts) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Chưa có số suất đã chốt hôm nay. Số hiện khi PHT xác nhận; chưa có số thì chưa nấu theo số nào.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.space3),
            for (final serving in today.servings) ...[
              const Divider(height: 1, color: AppColors.border),
              _ServingRow(serving: serving),
            ],
            if (today.countStatus == KitchenCountStatus.partial) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Bữa chưa xác nhận sẽ hiện khi PHT xác nhận số suất.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: AppLinkButton(
                label: 'Xem theo lớp',
                onPressed: onOpenClasses,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServingRow extends StatelessWidget {
  const _ServingRow({required this.serving});

  final SessionServings serving;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final block = serving.blockNote;
    return Semantics(
      container: true,
      label: [
        serving.label,
        ?block,
        '${serving.total} suất, ${serving.substitute} thay thế',
      ].join(', '),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.cardGap),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: serving.label,
                  children: [
                    if (block != null)
                      TextSpan(
                        text: ' · $block',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                  ],
                ),
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${serving.total}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
                Text(
                  '${serving.substitute} thay thế',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
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

/// Ô xem nhanh: icon và nhãn, cả ô chạm được.
class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
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
              padding: const EdgeInsets.all(AppSpacing.cardGap),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIconTile(icon: icon, tone: AppStatusTone.blue),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

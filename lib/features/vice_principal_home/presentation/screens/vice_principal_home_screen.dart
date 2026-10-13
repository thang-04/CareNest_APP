import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/cooking_status/data/fake_cooking_status_source.dart';
import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';
import 'package:carenest_app/features/vice_principal_home/data/fake_campus_today_source.dart';
import 'package:carenest_app/features/vice_principal_home/domain/campus_today.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Phó HT · Trang chủ cơ sở — mockup V01: hero + thẻ cơ sở → số trong ngày → Việc cần làm hôm nay.
/// Chỉ cơ sở được phân công (AUTH-02); số do BE tổng hợp (AUTH-08).
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

  // Quay lại từ màn con (đã chốt suất, đã duyệt) ⇒ tải lại để badge đúng
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeroHeader(
            greeting: 'Chào thầy,',
            name: today?.staffName ?? '',
            card: today == null
                ? (_error == null ? const AppSkeletonCard(lines: 1) : null)
                : _CampusCard(today: today),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.space4,
              AppSpacing.pagePadding,
              AppSpacing.space6,
            ),
            child: _buildBody(today),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CampusToday? today) {
    if (_error != null) {
      return AppErrorState(
        title: 'Chưa tải được số liệu cơ sở',
        message: 'Kiểm tra kết nối mạng rồi thử lại.',
        onRetry: _load,
      );
    }
    if (today == null) return const AppSkeletonList(rows: 4);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppStatRow(
          tiles: [
            AppStatTile(
              value: '${today.present}',
              label: 'Có mặt',
              tone: AppStatusTone.green,
            ),
            AppStatTile(
              value: '${today.excused}',
              label: 'Có phép',
              tone: AppStatusTone.approval,
            ),
            AppStatTile(
              value: '${today.absent}',
              label: 'Vắng',
              tone: AppStatusTone.red,
            ),
            AppStatTile(
              value: '${today.pendingApprovals}',
              label: 'Chờ duyệt',
              tone: AppStatusTone.orange,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Semantics(
          header: true,
          child: Text('Việc cần làm hôm nay', style: textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (today.tasks.isEmpty)
          const AppEmptyState(
            icon: AppIcons.checkCircle,
            title: 'Không còn việc nào',
            message: 'Các việc trong ngày của cơ sở đã xong.',
          )
        else
          for (final task in today.tasks) ...[
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
    );
  }
}

class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.today});

  final CampusToday today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(today.campusName, style: textTheme.titleSmall),
                Text(
                  '${today.classCount} lớp · ${today.present} bé có mặt / ${today.enrolled}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          const AppStatusBadge(label: 'Hôm nay', tone: AppStatusTone.blue),
        ],
      ),
    );
  }
}

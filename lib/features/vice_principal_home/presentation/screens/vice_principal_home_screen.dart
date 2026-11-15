import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_hero_header.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/vice_principal_home/data/fake_campus_today_source.dart';
import 'package:carenest_app/features/vice_principal_home/domain/campus_today.dart';
import 'package:carenest_app/features/vice_principal_home/presentation/widgets/stat_strip.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Phó HT · Trang chủ cơ sở — Figma PHT 01 (chỉ xem): dải chào + thẻ cơ sở, dải số hôm nay, "Theo dõi hôm nay".
/// Chỉ xem (AUTH-21, BE ADR-0026): mọi xử lý làm trên Web. Chỉ cơ sở được phân công (AUTH-02);
/// số, nhãn trạng thái do BE trả (AUTH-08).
class VicePrincipalHomeScreen extends StatefulWidget {
  const VicePrincipalHomeScreen({super.key, this.source});

  final CampusTodaySource? source;

  @override
  State<VicePrincipalHomeScreen> createState() =>
      _VicePrincipalHomeScreenState();
}

class _VicePrincipalHomeScreenState extends State<VicePrincipalHomeScreen> {
  late final CampusTodaySource _source =
      widget.source ?? FakeCampusTodaySource();
  CampusToday? _today;
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

  // Quay lại từ màn con ⇒ tải lại để số và badge theo BE mới nhất
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) _load();
  }

  static IconData _icon(CampusTaskKind kind) => switch (kind) {
    CampusTaskKind.mealCount => AppIcons.meal,
    CampusTaskKind.approvals => AppIcons.approval,
    CampusTaskKind.menu => AppIcons.menuBook,
    CampusTaskKind.children => AppIcons.childFace,
  };

  static AppStatusTone _tone(CampusBadgeLevel level) => switch (level) {
    CampusBadgeLevel.todo || CampusBadgeLevel.watch => AppStatusTone.orange,
    CampusBadgeLevel.fresh || CampusBadgeLevel.view => AppStatusTone.blue,
    CampusBadgeLevel.done => AppStatusTone.green,
  };

  void _openTask(CampusTaskKind kind) => switch (kind) {
    CampusTaskKind.mealCount => _open(RoutePaths.vicePrincipalMealConfirm),
    // Chờ xử lý là một tab ⇒ chuyển tab, không chồng màn
    CampusTaskKind.approvals => context.go(RoutePaths.vicePrincipalApprovals),
    CampusTaskKind.menu => _open(RoutePaths.vicePrincipalMenu),
    CampusTaskKind.children => _open(RoutePaths.vicePrincipalChildren),
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
            greeting: 'Chào thầy,',
            name: today?.staffName ?? '',
            card: _error != null
                ? null
                : today == null
                ? const AppSkeletonCard(lines: 1)
                : _CampusCard(today: today),
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

  List<Widget> _buildBody(CampusToday? today) {
    if (_error != null) {
      return [
        const SizedBox(height: AppSpacing.space3),
        AppErrorState(
          title: 'Chưa tải được số liệu cơ sở',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    if (today == null) return const [AppSkeletonList(rows: 4)];
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    return [
      StatStrip(
        items: [
          StatStripItem(
            value: '${today.present}',
            label: 'Có mặt',
            color: status.tone(AppStatusTone.green).foreground,
          ),
          StatStripItem(
            value: '${today.excused}',
            label: 'Có phép',
            color: status.tone(AppStatusTone.blue).foreground,
          ),
          StatStripItem(
            value: '${today.absent}',
            label: 'Vắng',
            color: status.tone(AppStatusTone.red).foreground,
          ),
          StatStripItem(
            value: '${today.pendingCount}',
            label: 'Chờ xử lý',
            color: status.tone(AppStatusTone.orange).foreground,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space5),
      Semantics(
        header: true,
        child: Text('Theo dõi hôm nay', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (today.tasks.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Chưa có việc cần theo dõi',
          message:
              'Số suất, việc chờ xử lý trên Web, thực đơn và trẻ của cơ sở sẽ hiện ở đây.',
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
              tone: _tone(task.level),
            ),
            onTap: () => _openTask(task.kind),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
    ];
  }
}

/// Thẻ cơ sở đè lên dải chào: tên cơ sở + "Hôm nay", số lớp và số bé có mặt (số BE trả).
class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.today});

  final CampusToday today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(today.campusName, style: textTheme.titleSmall),
              ),
              const SizedBox(width: AppSpacing.space2),
              const AppStatusBadge(label: 'Hôm nay', tone: AppStatusTone.blue),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '${today.classCount} lớp · ${today.present} bé có mặt / ${today.enrolled}',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

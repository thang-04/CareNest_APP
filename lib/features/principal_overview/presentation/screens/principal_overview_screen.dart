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
import 'package:carenest_app/core/widgets/app_progress_ring.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/core/widgets/app_task_card.dart';
import 'package:carenest_app/features/cooking_status/domain/cooking_status.dart';
import 'package:carenest_app/features/principal_overview/data/fake_school_overview_source.dart';
import 'package:carenest_app/features/principal_overview/domain/school_overview.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Hiệu trưởng · Tổng quan toàn trường (bố cục D): hai cơ sở cạnh nhau → chờ duyệt → đánh giá → toàn trường.
/// Mọi số do BE tổng hợp (AUTH-01, AUTH-08). Không có "Nghỉ phép nhân sự" (ngoài phạm vi CareNest, plan K5).
class PrincipalOverviewScreen extends StatefulWidget {
  const PrincipalOverviewScreen({super.key, this.source});

  final SchoolOverviewSource? source;

  @override
  State<PrincipalOverviewScreen> createState() =>
      _PrincipalOverviewScreenState();
}

class _PrincipalOverviewScreenState extends State<PrincipalOverviewScreen> {
  late final SchoolOverviewSource _source =
      widget.source ?? FakeSchoolOverviewSource();
  SchoolOverview? _overview;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final overview = await _source.loadToday();
      if (mounted) setState(() => _overview = overview);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  // Quay lại từ màn con (đã duyệt) ⇒ tải lại để mục chờ duyệt đúng
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
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
                  overview?.staffName ?? '',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (overview != null)
                  Text(
                    '${overview.schoolName} · ${DateLabels.weekdayDayMonth(overview.date)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          ..._buildBody(overview),
        ],
      ),
    );
  }

  List<Widget> _buildBody(SchoolOverview? overview) {
    if (_error != null) {
      return [
        AppErrorState(
          title: 'Chưa tải được tổng quan',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    if (overview == null) {
      return const [
        AppSkeletonCard(lines: 4),
        SizedBox(height: AppSpacing.sectionGap),
        AppSkeletonList(rows: 3),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    return [
      if (overview.campuses.isNotEmpty) ...[
        _CampusRow(
          campuses: overview.campuses,
          onOpen: () => _open(RoutePaths.principalCampuses),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
      ],
      Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                overview.pending.isEmpty
                    ? 'Chờ Hiệu trưởng duyệt'
                    : 'Chờ Hiệu trưởng duyệt (${overview.pending.length})',
                style: textTheme.titleMedium,
              ),
            ),
          ),
          AppLinkButton(
            label: 'Tất cả',
            onPressed: () => context.go(RoutePaths.principalApprovals),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space3),
      if (overview.pending.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không có yêu cầu chờ duyệt',
          message: 'Đề xuất Phó HT gửi lên sẽ hiện ở đây.',
        )
      else
        for (final batch in overview.pending) ...[
          AppTaskCard(
            icon: AppIcons.trophy,
            tone: AppStatusTone.approval,
            title: '${batch.title} · ${batch.proposals.length} bé',
            subtitle: '${batch.campusName} · đã qua Phó HT',
            trailing: const AppStatusBadge(
              label: 'Mới',
              tone: AppStatusTone.approval,
            ),
            onTap: () => _open(RoutePaths.principalRewardBatch(batch.id)),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
      const SizedBox(height: AppSpacing.sectionGap - AppSpacing.space2),
      Semantics(
        header: true,
        child: Text(overview.evaluationTitle, style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      AppCard(
        dense: true,
        child: Column(
          children: [
            for (final (i, row) in overview.evaluations.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.space3),
              _EvaluationBar(row: row),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sectionGap),
      Semantics(
        header: true,
        child: Text('Toàn trường', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      AppTaskCard(
        icon: AppIcons.childFace,
        tone: AppStatusTone.blue,
        title: 'Trẻ có mặt',
        subtitle:
            '${overview.present}/${overview.enrolled} bé · ${overview.presentRate}',
        onTap: () => _open(RoutePaths.principalChildren),
      ),
      const SizedBox(height: AppSpacing.space2),
      AppTaskCard(
        icon: AppIcons.menuBook,
        tone: AppStatusTone.approval,
        title: 'Thực đơn tuần',
        subtitle:
            '${overview.menusPublished}/${overview.campusCount} cơ sở đã công bố',
        onTap: () => _open(RoutePaths.principalMenu),
      ),
      const SizedBox(height: AppSpacing.space2),
      AppTaskCard(
        icon: AppIcons.building,
        tone: AppStatusTone.teal,
        title: 'Cơ sở và Phó HT phụ trách',
        subtitle:
            '${overview.campusCount} cơ sở · ${overview.confirmedMeals} suất đã chốt',
        onTap: () => _open(RoutePaths.principalCampuses),
      ),
    ];
  }
}

/// Các cơ sở cạnh nhau (bố cục D); chữ phóng lớn hoặc màn hẹp ⇒ xếp dọc.
class _CampusRow extends StatelessWidget {
  const _CampusRow({required this.campuses, required this.onOpen});

  final List<CampusSnapshot> campuses;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - AppSpacing.space3 * (campuses.length - 1)) /
            campuses.length;
        if (large || width < 136) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, campus) in campuses.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.space3),
                _CampusCard(campus: campus, onTap: onOpen, wide: true),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, campus) in campuses.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: _CampusCard(campus: campus, onTap: onOpen),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Thẻ một cơ sở: vòng tỉ lệ có mặt, suất đã chốt, trạng thái bếp (số BE trả).
class _CampusCard extends StatelessWidget {
  const _CampusCard({
    required this.campus,
    required this.onTap,
    this.wide = false,
  });

  final CampusSnapshot campus;
  final VoidCallback onTap;

  /// Xếp dọc ⇒ vòng nằm phải, thông tin bên trái.
  final bool wide;

  static AppStatusTone _kitchenTone(CookingStage stage) => switch (stage) {
    CookingStage.waiting => AppStatusTone.gray,
    CookingStage.cooking => AppStatusTone.blue,
    CookingStage.ready => AppStatusTone.teal,
    CookingStage.delivered => AppStatusTone.green,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final green = AppStatusColors.of(context).tone(AppStatusTone.green);
    final meals = campus.confirmedMeals;
    final stage = campus.kitchenStage;
    final ring = AppProgressRing(
      value: campus.presentRatio,
      label: campus.presentRate,
      caption: '${campus.present}/${campus.enrolled}',
      color: green.main,
      size: 80,
    );
    final info = <Widget>[
      Text(
        meals == null ? 'Chưa chốt suất' : 'Suất đã chốt',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      if (meals != null)
        Text(
          '$meals',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
      if (stage != null) ...[
        const SizedBox(height: AppSpacing.space2),
        AppStatusBadge(
          label: stage.label,
          tone: _kitchenTone(stage),
          icon: AppIcons.kitchen,
        ),
      ],
    ];
    final label = [
      campus.name,
      'có mặt ${campus.present}/${campus.enrolled}, ${campus.presentRate}',
      meals == null ? 'chưa chốt suất' : '$meals suất đã chốt',
      if (stage != null) 'bếp ${stage.label.toLowerCase()}',
    ].join(', ');
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campus.name, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.space3),
                  if (wide)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: info,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        ring,
                      ],
                    )
                  else ...[
                    ring,
                    const SizedBox(height: AppSpacing.space3),
                    ...info,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EvaluationBar extends StatelessWidget {
  const _EvaluationBar({required this.row});

  final GroupEvaluation row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    return Semantics(
      container: true,
      label: '${row.groupLabel}: ${row.percent}',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(row.groupLabel, style: textTheme.bodyMedium),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: row.ratio.clamp(0, 1).toDouble(),
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: status.track,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            row.percent,
            style: textTheme.labelLarge?.copyWith(
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

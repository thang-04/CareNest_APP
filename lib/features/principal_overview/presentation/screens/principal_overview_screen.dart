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
import 'package:carenest_app/features/principal_overview/data/fake_school_overview_source.dart';
import 'package:carenest_app/features/principal_overview/domain/school_overview.dart';
import 'package:carenest_app/routing/route_paths.dart';

/// Hiệu trưởng · Tổng quan toàn trường — Figma HT 01 (chỉ xem): dải chào + thẻ trường, ô số liệu toàn trường,
/// đánh giá trẻ theo khối, chờ xử lý. Mọi số do BE tổng hợp (AUTH-01, AUTH-08).
/// Không có "Nghỉ phép nhân sự" (ngoài phạm vi CareNest, plan K5).
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

  // Quay lại từ màn con ⇒ tải lại để số và mục chờ xử lý theo BE mới nhất
  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.space6),
        children: [
          AppHeroHeader(
            greeting: 'Chào cô,',
            name: overview?.staffName ?? '',
            card: _error != null
                ? null
                : overview == null
                ? const AppSkeletonCard(lines: 1)
                : _SchoolCard(overview: overview),
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
              children: _buildBody(overview),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(SchoolOverview? overview) {
    if (_error != null) {
      return [
        const SizedBox(height: AppSpacing.space3),
        AppErrorState(
          title: 'Chưa tải được tổng quan',
          message: 'Kiểm tra kết nối mạng rồi thử lại.',
          onRetry: _load,
        ),
      ];
    }
    if (overview == null) return const [AppSkeletonList(rows: 3)];
    final textTheme = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    return [
      _MetricGrid(
        tiles: [
          _MetricTile(
            icon: AppIcons.childFace,
            tone: AppStatusTone.blue,
            label: 'Trẻ có mặt',
            value: '${overview.present}/${overview.enrolled}',
            suffix: overview.presentRate,
            onTap: () => _open(RoutePaths.principalChildren),
          ),
          _MetricTile(
            icon: AppIcons.meal,
            tone: AppStatusTone.green,
            label: 'Suất ăn đã chốt',
            value: '${overview.confirmedMeals}',
            suffix: '${overview.mealCampuses} cơ sở',
          ),
          _MetricTile(
            icon: AppIcons.menuBook,
            tone: AppStatusTone.teal,
            label: 'Thực đơn tuần',
            value: '${overview.menusPublished}/${overview.campusCount}',
            suffix: 'cơ sở đã công bố',
            onTap: () => _open(RoutePaths.principalMenu),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space5),
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
              _EvaluationBar(row: row, track: status.track),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.space5),
      Semantics(
        header: true,
        child: Text('Chờ xử lý', style: textTheme.titleMedium),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (overview.pending.isEmpty)
        const AppEmptyState(
          icon: AppIcons.checkCircle,
          title: 'Không có việc chờ xử lý',
          message:
              'Đề xuất Phó HT gửi lên sẽ hiện ở đây, duyệt trên CareNest Web.',
        )
      else
        for (final batch in overview.pending) ...[
          AppTaskCard(
            icon: AppIcons.trophy,
            title: '${batch.title} · ${batch.proposals.length} bé',
            subtitle: '${batch.campusName} · đã qua Phó HT · duyệt trên Web',
            trailing: const AppStatusBadge(
              label: 'Mới',
              tone: AppStatusTone.blue,
            ),
            onTap: () => _open(RoutePaths.principalRewardBatch(batch.id)),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
    ];
  }
}

/// Thẻ trường đè lên dải chào: tên trường + số cơ sở, năm học + ngày.
class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.overview});

  final SchoolOverview overview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${overview.schoolName} · ${overview.campusCount} cơ sở',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'Năm học ${overview.schoolYear} · ${DateLabels.weekdayDayMonth(overview.date)}',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Lưới ô số liệu 2 cột như Figma; chữ phóng lớn ⇒ một cột thay vì ép hẹp.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.tiles});

  final List<_MetricTile> tiles;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space3),
            tile,
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space3),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Ô số liệu: icon tròn theo tông + nhãn, số lớn cùng tông + chữ phụ. Số do BE trả.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    required this.suffix,
    this.onTap,
  });

  final IconData icon;
  final AppStatusTone tone;
  final String label;
  final String value;
  final String suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = AppStatusColors.of(context).tone(tone);
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconTile(icon: icon, tone: tone, size: 32),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text.rich(
            TextSpan(
              text: value,
              style: textTheme.headlineSmall?.copyWith(
                color: colors.foreground,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
              children: [
                TextSpan(
                  text: ' $suffix',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: '$label: $value, $suffix',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _EvaluationBar extends StatelessWidget {
  const _EvaluationBar({required this.row, required this.track});

  final GroupEvaluation row;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                backgroundColor: track,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            row.percent,
            style: textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

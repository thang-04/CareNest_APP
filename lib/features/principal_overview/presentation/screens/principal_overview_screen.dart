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

/// Hiệu trưởng · Tổng quan toàn trường — mockup H01 (AUTH-01, AUTH-08). Bỏ ô "Nghỉ phép nhân sự"
/// (ngoài phạm vi CareNest, plan K5); thay bằng ô Cơ sở dẫn tới H08.
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeroHeader(
            greeting: 'Chào cô,',
            name: overview?.staffName ?? '',
            card: overview == null
                ? (_error == null ? const AppSkeletonCard(lines: 1) : null)
                : AppCard(
                    dense: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${overview.schoolName} · ${overview.campusCount} cơ sở',
                          style: textTheme.titleSmall,
                        ),
                        Text(
                          'Năm học ${overview.schoolYear} · ${DateLabels.weekdayDayMonth(overview.date)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.space4,
              AppSpacing.pagePadding,
              AppSpacing.space6,
            ),
            child: _buildBody(overview),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SchoolOverview? overview) {
    if (_error != null) {
      return AppErrorState(
        title: 'Chưa tải được tổng quan',
        message: 'Kiểm tra kết nối mạng rồi thử lại.',
        onRetry: _load,
      );
    }
    if (overview == null) return const AppSkeletonList(rows: 4);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TileGrid(
          tiles: [
            _OverviewTile(
              icon: AppIcons.childFace,
              label: 'Trẻ có mặt',
              value: '${overview.present}/${overview.enrolled}',
              suffix: overview.presentRate,
              tone: AppStatusTone.blue,
              onTap: () => _open(RoutePaths.principalChildren),
            ),
            _OverviewTile(
              icon: AppIcons.meal,
              label: 'Suất ăn đã chốt',
              value: '${overview.confirmedMeals}',
              suffix: '${overview.mealCampuses} cơ sở',
              tone: AppStatusTone.green,
            ),
            _OverviewTile(
              icon: AppIcons.menuBook,
              label: 'Thực đơn tuần',
              value: '${overview.menusPublished}/${overview.campusCount}',
              suffix: 'cơ sở đã công bố',
              tone: AppStatusTone.approval,
              onTap: () => _open(RoutePaths.principalMenu),
            ),
            _OverviewTile(
              icon: AppIcons.building,
              label: 'Cơ sở',
              value: '${overview.campusCount}',
              suffix: 'Phó HT phụ trách',
              tone: AppStatusTone.teal,
              onTap: () => _open(RoutePaths.principalCampuses),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Semantics(
          header: true,
          child: Text(overview.evaluationTitle, style: textTheme.titleSmall),
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
          child: Text('Chờ Hiệu trưởng duyệt', style: textTheme.titleSmall),
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
      ],
    );
  }
}

/// Lưới 2 cột; chữ phóng lớn ⇒ 1 cột để số không bị ép.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = large
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.space2) / 2;
        return Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    required this.tone,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final AppStatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = AppStatusColors.of(context).tone(tone);
    return Semantics(
      container: true,
      button: onTap != null,
      label: '$label: $value, $suffix',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIconTile(icon: icon, tone: tone, size: 36),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        label,
                        style: textTheme.labelMedium?.copyWith(
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
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.foreground,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                    children: [
                      TextSpan(
                        text: ' $suffix',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

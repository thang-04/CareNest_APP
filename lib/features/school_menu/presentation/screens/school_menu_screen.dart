import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/school_menu/data/fake_school_menu_source.dart';
import 'package:carenest_app/features/school_menu/domain/school_menu.dart';

/// Thực đơn tuần theo nhóm tuổi — mockup K02 (bếp, tab Thực đơn) và V06 (Phó HT). Chỉ xem:
/// thực đơn đã duyệt (NUT-08), lập và duyệt trên Web.
class SchoolMenuScreen extends StatefulWidget {
  const SchoolMenuScreen({
    super.key,
    required this.initialDay,
    required this.footerNote,
    this.asTab = false,
    this.bottom,
    this.campusId = 'campus-main',
    this.source = const FakeSchoolMenuSource(),
  });

  final DateTime initialDay;
  final String footerNote;

  /// Là tab ⇒ tiêu đề lớn trong nội dung; màn con ⇒ AppBar có nút Back.
  final bool asTab;

  /// Khối thêm cuối màn theo vai trò (vd. Phó HT: trạng thái duyệt + cân đối dinh dưỡng của nhóm, ngày đang chọn).
  final Widget Function(
    BuildContext context,
    SchoolMenuWeek week,
    String groupId,
    DateTime day,
  )?
  bottom;
  final String campusId;
  final SchoolMenuSource source;

  @override
  State<SchoolMenuScreen> createState() => _SchoolMenuScreenState();
}

class _SchoolMenuScreenState extends State<SchoolMenuScreen> {
  late Future<SchoolMenuWeek> _week = widget.source.loadWeek(widget.campusId);
  late DateTime _day = widget.initialDay;
  String _group = 'mam';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = FutureBuilder<SchoolMenuWeek>(
      future: _week,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: AppErrorState(
              title: 'Chưa tải được thực đơn',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: () => setState(
                () => _week = widget.source.loadWeek(widget.campusId),
              ),
            ),
          );
        }
        final week = snapshot.data;
        final weekEnd = week?.weekStart.add(const Duration(days: 4));
        final weekLabel = week == null
            ? ''
            : 'Tuần ${week.weekStart.day}–${DateLabels.dayMonth(weekEnd!)}';
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            if (widget.asTab) ...[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.space2,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Thực đơn', style: textTheme.headlineSmall),
                  ),
                  Text(
                    weekLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
            ] else if (week != null) ...[
              Text(
                weekLabel,
                style: textTheme.titleSmall?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
            if (week == null)
              const AppSkeletonList(rows: 4)
            else
              ..._content(context, week),
          ],
        );
      },
    );
    if (widget.asTab) return SafeArea(bottom: false, child: body);
    return Scaffold(
      appBar: AppBar(title: const Text('Thực đơn tuần')),
      body: body,
    );
  }

  List<Widget> _content(BuildContext context, SchoolMenuWeek week) {
    final textTheme = Theme.of(context).textTheme;
    final menu = week.days.entries
        .where((entry) => DateUtils.isSameDay(entry.key, _day))
        .firstOrNull
        ?.value[_group];
    return [
      AppDayStrip(
        days: week.days.keys.toList(),
        selected: _day,
        onChanged: (value) => setState(() => _day = value),
      ),
      const SizedBox(height: AppSpacing.space3),
      AppSegmented<String>(
        segments: week.groups,
        selected: _group,
        onChanged: (value) => setState(() => _group = value),
      ),
      const SizedBox(height: AppSpacing.space3),
      if (menu == null)
        const AppEmptyState(
          icon: AppIcons.menuBook,
          title: 'Không có thực đơn nhóm này',
          message: 'Cơ sở không có lớp thuộc nhóm tuổi này trong ngày.',
        )
      else ...[
        Text(
          'Nhóm ${menu.groupLabel} (${menu.ageRange}) · ${menu.childCount} bé · định lượng theo nhóm tuổi',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.space3),
        for (final meal in menu.meals) ...[
          AppCard(
            dense: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  AppIcons.meal,
                  size: AppSizes.iconTile,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meal.name} · ${meal.time}',
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        meal.dishes,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
        if (menu.alternatives.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Thực đơn thay thế · nhóm ${menu.groupLabel}',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.space2),
          for (final alt in menu.alternatives) ...[
            _AlternativeCard(alternative: alt),
            const SizedBox(height: AppSpacing.space2),
          ],
        ],
      ],
      if (widget.bottom != null) ...[
        const SizedBox(height: AppSpacing.space2),
        widget.bottom!(context, week, _group, _day),
      ],
      const SizedBox(height: AppSpacing.space3),
      Text(
        widget.footerNote,
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
    ];
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.alternative});

  final AlternativeMenu alternative;

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.of(
      context,
    ).tone(alternative.isAllergy ? AppStatusTone.teal : AppStatusTone.green);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${alternative.title} · ${alternative.count} bé',
            style: textTheme.titleSmall?.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: AppSpacing.space1),
          Semantics(
            label: [
              for (final (from, to) in alternative.swaps) '$from đổi sang $to',
            ].join(', '),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  for (final (i, (from, to)) in alternative.swaps.indexed) ...[
                    if (i > 0) const TextSpan(text: ' · '),
                    TextSpan(text: '$from '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        AppIcons.arrowRight,
                        size: AppSizes.iconBadge,
                        color: colors.foreground,
                      ),
                    ),
                    TextSpan(text: ' $to'),
                  ],
                ],
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

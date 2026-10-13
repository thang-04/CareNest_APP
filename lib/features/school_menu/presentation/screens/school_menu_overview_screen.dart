import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/core/widgets/app_status_badge.dart';
import 'package:carenest_app/features/nutrition_balance/data/fake_nutrition_balance_source.dart';
import 'package:carenest_app/features/nutrition_balance/domain/nutrition_balance.dart';
import 'package:carenest_app/features/school_menu/data/fake_school_menu_source.dart';
import 'package:carenest_app/features/school_menu/domain/school_menu.dart';
import 'package:carenest_app/routing/route_paths.dart';

typedef _DayMenu = (SchoolMenuWeek, Map<String, NutritionBalance?>);

/// Hiệu trưởng · Thực đơn tuần (chỉ xem) — mockup H07: theo cơ sở, mỗi nhóm tuổi một thẻ bữa trưa
/// kèm năng lượng ngày; nhãn và tóm tắt dinh dưỡng do BE trả (NUT-06, NUT-08; chung hay riêng P-07).
class SchoolMenuOverviewScreen extends StatefulWidget {
  const SchoolMenuOverviewScreen({
    super.key,
    required this.initialDay,
    required this.campuses,
    this.menuSource = const FakeSchoolMenuSource(),
    this.nutritionSource = const FakeNutritionBalanceSource(),
  });

  final DateTime initialDay;

  /// (id, nhãn) các cơ sở trong phạm vi.
  final List<(String, String)> campuses;
  final SchoolMenuSource menuSource;
  final NutritionBalanceSource nutritionSource;

  @override
  State<SchoolMenuOverviewScreen> createState() =>
      _SchoolMenuOverviewScreenState();
}

class _SchoolMenuOverviewScreenState extends State<SchoolMenuOverviewScreen> {
  late String _campusId = widget.campuses.first.$1;
  late DateTime _day = widget.initialDay;
  late Future<_DayMenu> _data = _load();

  Future<_DayMenu> _load() async {
    final campusId = _campusId;
    final day = _day;
    final week = await widget.menuSource.loadWeek(campusId);
    final groups = week.groups.map((group) => group.$1).toList();
    final balances = await Future.wait([
      for (final id in groups)
        widget.nutritionSource.load(campusId: campusId, groupId: id, day: day),
    ]);
    return (week, {for (final (i, id) in groups.indexed) id: balances[i]});
  }

  // Đổi cơ sở / ngày ⇒ tải lại theo ngữ cảnh mới
  void _change({String? campusId, DateTime? day}) => setState(() {
    _campusId = campusId ?? _campusId;
    _day = day ?? _day;
    _data = _load();
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<_DayMenu>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        final week = data?.$1;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Thực đơn tuần'),
            actions: [
              if (week != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space4),
                  child: Center(
                    child: Text(
                      '${week.weekStart.day}–${DateLabels.dayMonth(week.weekStart.add(const Duration(days: 4)))}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              if (widget.campuses.length > 1) ...[
                AppSegmented<String>(
                  segments: widget.campuses,
                  selected: _campusId,
                  onChanged: (value) => _change(campusId: value),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
              if (snapshot.hasError)
                AppErrorState(
                  title: 'Chưa tải được thực đơn',
                  message: 'Kiểm tra kết nối mạng rồi thử lại.',
                  onRetry: _change,
                )
              else if (data == null)
                const AppSkeletonList(rows: 4)
              else
                ..._content(context, data),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'Hiệu trưởng chỉ xem. Thực đơn được lập, duyệt và công bố trên CareNest Web.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, _DayMenu data) {
    final (week, balances) = data;
    final textTheme = Theme.of(context).textTheme;
    final menus = week.days.entries
        .where((entry) => DateUtils.isSameDay(entry.key, _day))
        .firstOrNull
        ?.value;
    final weekday = DateLabels.weekdayDayMonth(_day).split(',').first;
    return [
      if (week.publishedNote case final note?) ...[
        AppCard(
          dense: true,
          child: Row(
            children: [
              const Icon(
                AppIcons.checkCircle,
                size: AppSizes.iconInline,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: Text(note, style: textTheme.titleSmall)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      AppDayStrip(
        days: week.days.keys.toList(),
        selected: _day,
        onChanged: (value) => _change(day: value),
      ),
      const SizedBox(height: AppSpacing.space3),
      for (final (groupId, groupLabel) in week.groups)
        if (menus?[groupId] case final menu?) ...[
          _GroupCard(
            title: '$groupLabel · $weekday',
            lunch: menu.meals.length > 1
                ? menu.meals[1].dishes
                : menu.meals.first.dishes,
            balance: balances[groupId],
            onTap: balances[groupId] == null
                ? null
                : () => context.push(
                    RoutePaths.principalNutritionOf(_campusId, groupId, _day),
                  ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
      if (week.nutritionSummary case final summary?) ...[
        const SizedBox(height: AppSpacing.space2),
        AppBanner(message: summary),
      ],
    ];
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.lunch,
    required this.balance,
    required this.onTap,
  });

  final String title;
  final String lunch;
  final NutritionBalance? balance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final balance = this.balance;
    return AppCard(
      flush: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
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
                    Text(title, style: textTheme.titleSmall),
                    Text(
                      lunch,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (balance != null) ...[
                const SizedBox(width: AppSpacing.space2),
                AppStatusBadge(
                  label: balance.dayEnergy,
                  tone: balance.energyMet
                      ? AppStatusTone.green
                      : AppStatusTone.orange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

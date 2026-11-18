import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_filter_chip.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/data/fake_kitchen_day_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';

/// Bếp · Thực đơn hôm nay (tab): chọn nhóm tuổi, bữa ⇒ món và nguyên liệu gam/trẻ.
/// Món theo khối Nhà trẻ / Mẫu giáo (NUT-13), gam/trẻ theo nhóm tuổi (NUT-18). Chỉ xem.
class KitchenMenuScreen extends StatefulWidget {
  const KitchenMenuScreen({super.key, this.source});

  final KitchenDaySource? source;

  @override
  State<KitchenMenuScreen> createState() => _KitchenMenuScreenState();
}

class _KitchenMenuScreenState extends State<KitchenMenuScreen> {
  late final KitchenDaySource _source = widget.source ?? FakeKitchenDaySource();
  late Future<KitchenDay> _day = _source.loadDay();
  int? _groupId;
  MealSession? _session;

  static String _grams(num value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return '$text g';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<KitchenDay>(
      future: _day,
      builder: (context, snapshot) => Padding(
        padding: MediaQuery.paddingOf(context).copyWith(bottom: 0),
        child: switch (snapshot) {
          AsyncSnapshot(hasError: true) => Center(
            child: AppErrorState(
              title: 'Chưa tải được thực đơn',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: () => setState(() {
                _day = _source.loadDay();
              }),
            ),
          ),
          AsyncSnapshot(hasData: true, :final data?) => _body(data),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.pagePadding),
            child: AppSkeletonList(rows: 5),
          ),
        },
      ),
    );
  }

  Widget _body(KitchenDay day) {
    final textTheme = Theme.of(context).textTheme;
    final header = [
      Semantics(
        header: true,
        child: Text('Thực đơn hôm nay', style: textTheme.titleLarge),
      ),
      Text(
        DateLabels.weekdayDate(day.date),
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: AppSpacing.space4),
    ];
    if (day.dayOff ||
        day.menuStatus != KitchenMenuStatus.published ||
        day.ageGroups.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          ...header,
          AppEmptyState(
            icon: AppIcons.meal,
            title: day.dayOff ? 'Ngày nghỉ' : 'Chưa có thực đơn đã công bố',
            message: day.dayOff
                ? 'Bếp không phục vụ bán trú hôm nay.'
                : 'Thực đơn hiện khi Phó hiệu trưởng công bố.',
          ),
        ],
      );
    }
    final group =
        day.ageGroups.where((item) => item.id == _groupId).firstOrNull ??
        day.ageGroups.first;
    final session = group.sessions.contains(_session)
        ? _session!
        : group.sessions.first;
    final dishes = day.dishesFor(group, session);
    final servings = day
        .servingsOf(session)
        .where((row) => row.ageGroupId == group.id)
        .fold<int>(0, (sum, row) => sum + row.normal + row.substitute);
    final number = textTheme.titleSmall?.copyWith(
      fontFeatures: AppTextStyles.tabularFigures,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        ...header,
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final item in day.ageGroups)
              AppFilterChip(
                label: item.name,
                selected: item.id == group.id,
                onSelected: () => setState(() => _groupId = item.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        AppSegmented<MealSession>(
          segments: [
            for (final item in group.sessions) (item, item.shortLabel),
          ],
          selected: session,
          onChanged: (value) => setState(() => _session = value),
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          [
            '${group.name} · ${session.label}',
            if (servings > 0) '$servings suất',
          ].join(' · '),
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.space2),
        if (dishes.isEmpty)
          Text(
            'Bữa này chưa có món.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          )
        else
          for (final dish in dishes) ...[
            AppCard(
              flush: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.pagePadding,
                      AppSpacing.pagePadding,
                      0,
                    ),
                    child: Text(dish.name, style: textTheme.titleMedium),
                  ),
                  AppDividedColumn(
                    children: [
                      for (final item in dish.ingredientsFor(group.id))
                        AppListRow(
                          title: item.foodName,
                          trailing: Text(
                            _grams(item.gramsPerChild),
                            style: number,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
        Text(
          'Định lượng tính cho 1 trẻ.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

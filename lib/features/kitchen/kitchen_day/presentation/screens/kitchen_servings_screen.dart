import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_segmented.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/data/fake_kitchen_day_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/presentation/widgets/meal_count_table.dart';

/// Bếp · Suất ăn theo lớp từng bữa (NUT-17). Chỉ số đã xác nhận (NUT-02, NUT-03),
/// không tên trẻ (AUTH-05); số do BE trả, như bảng "Suất ăn theo lớp" của Web.
class KitchenServingsScreen extends StatefulWidget {
  const KitchenServingsScreen({super.key, this.source});

  final KitchenDaySource? source;

  @override
  State<KitchenServingsScreen> createState() => _KitchenServingsScreenState();
}

class _KitchenServingsScreenState extends State<KitchenServingsScreen> {
  late final KitchenDaySource _source = widget.source ?? FakeKitchenDaySource();
  late Future<KitchenDay> _day = _source.loadDay();
  MealSession? _session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suất ăn theo lớp')),
      body: FutureBuilder<KitchenDay>(
        future: _day,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasError: true) => Center(
            child: AppErrorState(
              title: 'Chưa tải được suất ăn',
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

  static List<(String, List<ClassServings>)> _byAgeGroup(
    KitchenDay day,
    List<ClassServings> rows,
  ) {
    final groups = [
      for (final group in day.ageGroups)
        (group.name, rows.where((row) => row.ageGroupId == group.id).toList()),
    ];
    final known = {for (final group in day.ageGroups) group.id};
    final other = rows.where((row) => !known.contains(row.ageGroupId)).toList();
    return [
      for (final item in groups)
        if (item.$2.isNotEmpty) item,
      if (other.isNotEmpty) ('Lớp khác', other),
    ];
  }

  Widget _body(KitchenDay day) {
    if (day.dayOff) {
      return const Center(
        child: AppEmptyState(
          icon: AppIcons.calendarOff,
          title: 'Ngày nghỉ',
          message: 'Bếp không phục vụ bán trú hôm nay.',
        ),
      );
    }
    final sessions = day.servedSessions;
    if (sessions.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: AppIcons.meal,
          title: 'Chưa có suất đã xác nhận',
          message: 'Số suất hiện khi nhà trường xác nhận.',
        ),
      );
    }
    final session = sessions.contains(_session) ? _session! : sessions.first;
    final rows = day.servingsOf(session);
    final normal = rows.fold<int>(0, (sum, row) => sum + row.normal);
    final substitute = rows.fold<int>(0, (sum, row) => sum + row.substitute);
    final confirmedAt = day.confirmedAt;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        if (sessions.length > 1) ...[
          AppSegmented<MealSession>(
            segments: [for (final item in sessions) (item, item.shortLabel)],
            selected: session,
            onChanged: (value) => setState(() => _session = value),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
        if (day.countStatus == KitchenCountStatus.partial) ...[
          AppBanner(
            kind: AppBannerKind.warning,
            message: day.countStatus.label,
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
        AppStatRow(
          tiles: [
            AppStatTile(
              value: '${normal + substitute}',
              label: 'Tổng suất',
              tone: AppStatusTone.blue,
            ),
            AppStatTile(value: '$normal', label: 'Thường'),
            AppStatTile(
              value: '$substitute',
              label: 'Thay thế',
              tone: AppStatusTone.teal,
            ),
          ],
        ),
        // Gom theo nhóm tuổi (NUT-17); lớp chưa rõ nhóm để cuối
        for (final (title, groupRows) in _byAgeGroup(day, rows)) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            '$title · ${groupRows.fold<int>(0, (sum, row) => sum + row.normal + row.substitute)} suất',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.space2),
          MealCountTable(
            classes: [
              for (final row in groupRows)
                ClassMealCount(
                  className: row.classroomName,
                  regular: row.normal,
                  alternative: row.substitute,
                ),
            ],
          ),
        ],
        if (confirmedAt != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Đã xác nhận lúc ${DateLabels.time24(confirmedAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_day_strip.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/data/fake_kitchen_menu_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_menu/domain/kitchen_menu.dart';

/// Bếp · tab Thực đơn (phương án B, user 25/11): thực đơn đã công bố của ngày đang chọn, món theo
/// bữa × khối (NUT-08, NUT-13). Chỉ xem; đổi ngày trong tuần bằng dải ngày.
class KitchenMenuScreen extends StatefulWidget {
  const KitchenMenuScreen({
    super.key,
    this.source = const FakeKitchenMenuSource(),
  });

  final KitchenMenuSource source;

  @override
  State<KitchenMenuScreen> createState() => _KitchenMenuScreenState();
}

class _KitchenMenuScreenState extends State<KitchenMenuScreen> {
  /// null ⇒ hôm nay theo máy chủ (lần mở đầu)
  DateTime? _date;
  late Future<KitchenMenuDay> _day = widget.source.loadDay();

  /// Thứ Hai – Thứ Sáu của tuần đang xem, lấy theo ngày BE trả lần đầu
  List<DateTime> _week = const [];

  void _open(DateTime date) => setState(() {
    _date = date;
    _day = widget.source.loadDay(date);
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<KitchenMenuDay>(
        future: _day,
        builder: (context, snapshot) {
          final day = snapshot.data;
          if (day != null && _week.isEmpty) {
            final monday = mondayOf(day.date);
            _week = [
              for (var i = 0; i < 5; i++)
                DateTime(monday.year, monday.month, monday.day + i),
            ];
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.space2,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Thực đơn', style: textTheme.headlineSmall),
                  ),
                  if (_week.isNotEmpty)
                    Text(
                      'Tuần ${_week.first.day}–${DateLabels.dayMonth(_week.last)}',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              if (_week.isNotEmpty) ...[
                AppDayStrip(
                  days: _week,
                  selected: _date ?? day?.date ?? _week.first,
                  onChanged: _open,
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
              ..._content(context, snapshot),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AsyncSnapshot<KitchenMenuDay> snapshot,
  ) {
    if (snapshot.hasError) {
      return [
        AppErrorState(
          title: 'Chưa tải được thực đơn',
          message: loadFailureMessage(snapshot.error),
          onRetry: () => setState(() {
            _day = widget.source.loadDay(_date);
          }),
        ),
      ];
    }
    final day = snapshot.data;
    if (day == null || snapshot.connectionState == ConnectionState.waiting) {
      return const [AppSkeletonList(rows: 3)];
    }
    if (day.isDayOff) {
      return const [
        AppEmptyState(
          title: 'Ngày nghỉ',
          message: 'Trường không tổ chức ăn ngày này.',
        ),
      ];
    }
    if (!day.published || day.sessions.isEmpty) {
      return const [
        AppEmptyState(
          icon: AppIcons.meal,
          title: 'Thực đơn tuần này chưa công bố',
          message: 'Phó hiệu trưởng phụ trách dinh dưỡng công bố trên Web.',
        ),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    return [
      for (final session in day.sessions) ...[
        AppCard(
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(session.label, style: textTheme.titleMedium),
              for (final block in session.blocks) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  block.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                for (final dish in block.dishes)
                  Text(dish, style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
      ],
      Text(
        'Chỉ xem. Số suất thay thế theo lớp xem ở Suất ăn theo lớp.',
        style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
    ];
  }
}

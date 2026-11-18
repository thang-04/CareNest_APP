import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_list_row.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/data/fake_kitchen_day_source.dart';
import 'package:carenest_app/features/kitchen/kitchen_day/domain/kitchen_day.dart';

/// Bếp · Thực phẩm cần trong ngày theo Hàng tươi / Hàng khô (NUT-07, NUT-10).
/// Số lượng do BE tính từ suất đã xác nhận; App chỉ hiển thị.
class FoodNeedsScreen extends StatefulWidget {
  const FoodNeedsScreen({super.key, this.source});

  final KitchenDaySource? source;

  @override
  State<FoodNeedsScreen> createState() => _FoodNeedsScreenState();
}

class _FoodNeedsScreenState extends State<FoodNeedsScreen> {
  late final KitchenDaySource _source = widget.source ?? FakeKitchenDaySource();
  late Future<KitchenDay> _day = _source.loadDay();

  static String _quantity(FoodNeed food) {
    final value = food.quantity;
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return '$text ${food.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thực phẩm cần')),
      body: FutureBuilder<KitchenDay>(
        future: _day,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasError: true) => Center(
            child: AppErrorState(
              title: 'Chưa tải được thực phẩm cần',
              message: 'Kiểm tra kết nối mạng rồi thử lại.',
              onRetry: () => setState(() {
                _day = _source.loadDay();
              }),
            ),
          ),
          AsyncSnapshot(hasData: true, :final data?) => _body(data),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.pagePadding),
            child: AppSkeletonList(rows: 6),
          ),
        },
      ),
    );
  }

  Widget _body(KitchenDay day) {
    if (day.foods.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: AppIcons.meal,
          title: 'Chưa có lượng thực phẩm',
          message: 'Cần thực đơn đã công bố và số suất đã xác nhận.',
        ),
      );
    }
    final textTheme = Theme.of(context).textTheme;
    final number = textTheme.titleSmall?.copyWith(
      fontFeatures: AppTextStyles.tabularFigures,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        for (final storage in FoodStorage.values)
          if (day.foods.any((food) => food.storage == storage)) ...[
            Text(storage.label, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.space2),
            AppCard(
              flush: true,
              child: AppDividedColumn(
                children: [
                  for (final food in day.foods.where(
                    (food) => food.storage == storage,
                  ))
                    AppListRow(
                      title: food.name,
                      trailing: Text(_quantity(food), style: number),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
        Text(
          'Số lượng tính theo suất đã xác nhận.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

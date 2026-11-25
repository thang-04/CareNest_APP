import 'package:flutter/material.dart';

import 'package:carenest_app/core/integration/load_failure.dart';
import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen/food_quantities/data/fake_food_quantity_source.dart';
import 'package:carenest_app/features/kitchen/food_quantities/domain/food_quantities.dart';

/// Lượng thực phẩm cần trong ngày (BE `KitchenDayResponse.foods`), chia hàng tươi / hàng khô.
/// Chỉ hiển thị số BE tính (NUT-06, NUT-07), không tính lại. Kho, kiểm nhận hàng do PHT ghi trên
/// Web (NUT-11, NUT-12) nên không có phiếu xuất kho ở đây.
class FoodQuantitiesScreen extends StatefulWidget {
  const FoodQuantitiesScreen({super.key, this.source});

  final FoodQuantitySource? source;

  @override
  State<FoodQuantitiesScreen> createState() => _FoodQuantitiesScreenState();
}

class _FoodQuantitiesScreenState extends State<FoodQuantitiesScreen> {
  late final FoodQuantitySource _source =
      widget.source ?? FakeFoodQuantitySource();
  late Future<FoodNeedDay?> _day = _source.loadDay();

  // Nhãn như web (CareNest_FE kitchenRecordConstants FOOD_STORAGE_LABELS)
  static String _storageLabel(FoodStorage storage) => switch (storage) {
    FoodStorage.fresh => 'Hàng tươi',
    FoodStorage.dry => 'Hàng khô',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lượng thực phẩm')),
      body: FutureBuilder<FoodNeedDay?>(
        future: _day,
        builder: (context, snapshot) {
          final day = snapshot.data;
          return switch (snapshot) {
            AsyncSnapshot(hasError: true) => Center(
              child: AppErrorState(
                title: 'Chưa tải được lượng thực phẩm',
                message: loadFailureMessage(snapshot.error),
                onRetry: () => setState(() {
                  _day = _source.loadDay();
                }),
              ),
            ),
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: AppSkeletonList(rows: 6),
              ),
            _ when day == null || day.needs.isEmpty => const Center(
              child: AppEmptyState(
                icon: AppIcons.meal,
                title: 'Chưa có lượng thực phẩm',
                message:
                    'Lượng hiện khi thực đơn đã công bố và PHT đã xác nhận số suất.',
              ),
            ),
            _ => _content(context, day),
          };
        },
      ),
    );
  }

  Widget _content(BuildContext context, FoodNeedDay day) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Text('Hôm nay · ${DateLabels.weekdayDayMonth(day.date)}', style: muted),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Cần cho cả ngày theo số suất đã chốt các bữa, đã cộng phần thải bỏ.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        for (final storage in FoodStorage.values)
          if (day.needs.where((need) => need.storage == storage).toList()
              case final needs when needs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            _StorageCard(label: _storageLabel(storage), needs: needs),
          ],
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Kho khô và kiểm nhận hàng tươi do PHT ghi trên Web.',
          style: muted,
        ),
      ],
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.label, required this.needs});

  final String label;
  final List<FoodNeed> needs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              '$label · ${needs.length} thực phẩm',
              style: textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          for (final (i, need) in needs.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Semantics(
              container: true,
              label: '${need.food}: ${need.amount}',
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.minimumTapTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(need.food, style: textTheme.bodyLarge),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      need.amount,
                      style: textTheme.titleSmall?.copyWith(
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

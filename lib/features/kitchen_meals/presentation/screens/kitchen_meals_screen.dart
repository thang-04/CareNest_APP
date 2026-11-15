import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/core/widgets/app_stat_tile.dart';
import 'package:carenest_app/core/widgets/app_state_view.dart';
import 'package:carenest_app/features/kitchen_meals/data/fake_kitchen_meals_source.dart';
import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';
import 'package:carenest_app/features/kitchen_meals/presentation/widgets/meal_count_table.dart';

/// Suất ăn đã chốt theo lớp — mockup K03. Chỉ xem, chỉ số đã xác nhận (NUT-02, NUT-03);
/// không có tên trẻ (AUTH-05).
class KitchenMealsScreen extends StatefulWidget {
  const KitchenMealsScreen({super.key, this.source});

  final KitchenMealsSource? source;

  @override
  State<KitchenMealsScreen> createState() => _KitchenMealsScreenState();
}

class _KitchenMealsScreenState extends State<KitchenMealsScreen> {
  late final KitchenMealsSource _source =
      widget.source ?? FakeKitchenMealsSource();
  late Future<MealCountSheet?> _sheet = _source.loadSheet();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MealCountSheet?>(
      future: _sheet,
      builder: (context, snapshot) {
        final sheet = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Suất ăn đã chốt'),
            actions: [
              if (sheet != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space4),
                  child: Center(
                    child: Text(
                      sheet.mealLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true) => Center(
              child: AppErrorState(
                title: 'Chưa tải được suất ăn',
                message: 'Kiểm tra kết nối mạng rồi thử lại.',
                onRetry: () => setState(() => _sheet = _source.loadSheet()),
              ),
            ),
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: AppSkeletonList(rows: 5),
              ),
            _ when sheet == null => const Center(
              child: AppEmptyState(
                icon: AppIcons.meal,
                title: 'Chưa có số suất đã chốt',
                message:
                    'Số suất hiện khi nhà trường xác nhận. Chưa có số thì chưa nấu theo số nào.',
              ),
            ),
            _ => _SheetBody(sheet: sheet),
          },
        );
      },
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.sheet});

  final MealCountSheet sheet;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppStatRow(
          tiles: [
            AppStatTile(
              value: '${sheet.total}',
              label: 'Tổng suất',
              tone: AppStatusTone.blue,
            ),
            AppStatTile(value: '${sheet.regular}', label: 'Thường'),
            AppStatTile(
              value: '${sheet.alternative}',
              label: 'Thay thế',
              tone: AppStatusTone.teal,
            ),
          ],
        ),
        if (sheet.adjustmentNote != null) ...[
          const SizedBox(height: AppSpacing.space3),
          AppBanner(
            kind: AppBannerKind.warning,
            message: sheet.adjustmentNote!,
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        MealCountTable(
          classes: sheet.classes,
          footer: 'Chỉ xem, không sửa được.',
        ),
      ],
    );
  }
}

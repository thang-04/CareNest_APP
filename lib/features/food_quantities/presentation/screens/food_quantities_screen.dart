import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/layouts/app_bottom_dock.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/core/widgets/app_banner.dart';
import 'package:carenest_app/core/widgets/app_button.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/core/widgets/app_coming_soon.dart';
import 'package:carenest_app/core/widgets/app_skeleton.dart';
import 'package:carenest_app/features/food_quantities/data/fake_food_quantity_source.dart';
import 'package:carenest_app/features/food_quantities/domain/food_quantities.dart';

/// Định lượng thực phẩm — mockup K04. Chỉ hiển thị số BE tính (NUT-06, NUT-07), không tính lại.
class FoodQuantitiesScreen extends StatelessWidget {
  const FoodQuantitiesScreen({
    super.key,
    this.source = const FakeFoodQuantitySource(),
  });

  final FoodQuantitySource source;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Định lượng thực phẩm')),
      body: FutureBuilder<QuantityPlan>(
        future: source.loadPlan(),
        builder: (context, snapshot) {
          final plan = snapshot.data;
          if (plan == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: AppSkeletonList(rows: 6),
            );
          }
          final teal = AppStatusColors.of(context).tone(AppStatusTone.teal);
          final header = textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
          );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              if (plan.slip case final slip?) ...[
                AppBanner(
                  kind: AppBannerKind.success,
                  title: 'Phiếu xuất kho ${slip.code} · Đã duyệt',
                  message:
                      '${slip.approvedBy} duyệt lúc ${DateLabels.time24(slip.approvedAt)}',
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
              AppCard(
                flush: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space4,
                          AppSpacing.space4,
                          AppSpacing.space4,
                          AppSpacing.space2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'THỰC PHẨM · ${plan.mealLabel.toUpperCase()} (${plan.servings} SUẤT)',
                                style: header,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Text('CẦN DÙNG', style: header),
                          ],
                        ),
                      ),
                    ),
                    for (final (i, line) in plan.lines.indexed) ...[
                      if (i > 0) const Divider(),
                      Semantics(
                        container: true,
                        label: '${line.food}, ${line.usage}: ${line.amount}',
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space4,
                            vertical: AppSpacing.space3,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.food,
                                      style: textTheme.titleSmall,
                                    ),
                                    Text(
                                      line.usage,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                line.amount,
                                style: textTheme.titleSmall?.copyWith(
                                  fontFeatures: AppTextStyles.tabularFigures,
                                  color: line.forAlternative
                                      ? teal.foreground
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space2),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomDock(
        children: [
          AppButton(
            label: 'Xem phiếu xuất kho & cách chế biến',
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () =>
                openComingSoon(context, 'Phiếu xuất kho & cách chế biến'),
          ),
        ],
      ),
    );
  }
}

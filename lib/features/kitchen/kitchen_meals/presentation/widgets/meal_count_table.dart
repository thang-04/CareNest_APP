import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/features/kitchen/kitchen_meals/domain/kitchen_meals.dart';

/// Bảng suất theo lớp — K03 bếp và V04 Phó HT. Số do BE trả; không tên trẻ.
class MealCountTable extends StatelessWidget {
  const MealCountTable({
    super.key,
    required this.classes,
    this.footer,
    this.showAlternative = true,
  });

  final List<ClassMealCount> classes;
  final String? footer;

  /// false ⇒ một cột "SUẤT" (NUT-23 25/11 bỏ suất thay thế); màn Phó HT xem thử giữ 2 cột cũ.
  final bool showAlternative;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teal = AppStatusColors.of(context).tone(AppStatusTone.teal);
    final header = textTheme.labelSmall?.copyWith(color: AppColors.textMuted);
    final number = textTheme.titleSmall?.copyWith(
      fontFeatures: AppTextStyles.tabularFigures,
    );
    return AppCard(
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
                  Expanded(flex: 3, child: Text('LỚP', style: header)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      showAlternative ? 'THƯỜNG' : 'SUẤT',
                      textAlign: TextAlign.end,
                      style: header,
                    ),
                  ),
                  if (showAlternative)
                    Expanded(
                      flex: 2,
                      child: Text(
                        'THAY THẾ',
                        textAlign: TextAlign.end,
                        style: header,
                      ),
                    ),
                ],
              ),
            ),
          ),
          for (final row in classes)
            Semantics(
              container: true,
              label: [
                row.className,
                if (showAlternative) ...[
                  '${row.regular} suất thường',
                  '${row.alternative} suất thay thế',
                ] else
                  '${row.servings} suất',
                ?row.note,
                if (row.changed) 'có điều chỉnh chờ duyệt',
              ].join(', '),
              excludeSemantics: true,
              child: Container(
                color: row.changed ? AppColors.warningSoft : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.className, style: textTheme.titleSmall),
                          if (row.note != null)
                            Text(
                              row.note!,
                              style: textTheme.labelMedium?.copyWith(
                                color: teal.foreground,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        showAlternative ? '${row.regular}' : '${row.servings}',
                        textAlign: TextAlign.end,
                        style: number,
                      ),
                    ),
                    if (showAlternative)
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${row.alternative}',
                          textAlign: TextAlign.end,
                          style: number?.copyWith(color: teal.foreground),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                footer!,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

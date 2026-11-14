import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';
import 'package:carenest_app/core/widgets/app_card.dart';
import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';

/// Bảng suất theo lớp (thường / thay thế) — Figma Bếp 03 và V04 Phó HT. Số do BE trả; không tên trẻ.
class MealCountTable extends StatelessWidget {
  const MealCountTable({super.key, required this.classes, this.footer});

  final List<ClassMealCount> classes;
  final String? footer;

  // Cột thay thế rộng hơn để chứa ghi chú dị ứng cạnh số
  static const _classFlex = 3;
  static const _regularFlex = 2;
  static const _alternativeFlex = 4;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final header = textTheme.labelSmall?.copyWith(color: AppColors.textMuted);
    const divider = Divider(
      indent: AppSpacing.space4,
      endIndent: AppSpacing.space4,
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
                AppSpacing.space3,
                AppSpacing.space4,
                AppSpacing.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _classFlex,
                    child: Text('LỚP', style: header),
                  ),
                  Expanded(
                    flex: _regularFlex,
                    child: Text(
                      'THƯỜNG',
                      textAlign: TextAlign.end,
                      style: header,
                    ),
                  ),
                  Expanded(
                    flex: _alternativeFlex,
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
          for (final (i, row) in classes.indexed) ...[
            // Dòng có điều chỉnh tô nền riêng ⇒ bỏ kẻ quanh nó cho gọn
            if (!row.changed && !(i > 0 && classes[i - 1].changed)) divider,
            _ClassRow(
              row: row,
              footer: i == classes.length - 1 ? footer : null,
            ),
          ],
          if (classes.isEmpty && footer != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(footer!, style: _footerStyle(textTheme)),
            ),
        ],
      ),
    );
  }

  static TextStyle? _footerStyle(TextTheme textTheme) => textTheme.labelMedium
      ?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w400);
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.row, this.footer});

  final ClassMealCount row;

  /// Dòng chú thích nhỏ dưới dòng cuối bảng.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final teal = AppStatusColors.of(context).tone(AppStatusTone.teal);
    final number = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: AppTextStyles.tabularFigures,
    );
    final content = Semantics(
      container: true,
      label: [
        row.className,
        '${row.regular} suất thường',
        '${row.alternative} suất thay thế',
        ?row.note,
        if (row.changed) 'có điều chỉnh',
      ].join(', '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: MealCountTable._classFlex,
            child: Text(row.className, style: textTheme.titleSmall),
          ),
          Expanded(
            flex: MealCountTable._regularFlex,
            child: Text(
              '${row.regular}',
              textAlign: TextAlign.end,
              style: number,
            ),
          ),
          Expanded(
            flex: MealCountTable._alternativeFlex,
            child: Text.rich(
              TextSpan(
                text: '${row.alternative}',
                children: [
                  if (row.note != null)
                    TextSpan(
                      text: ' (${row.note})',
                      style: textTheme.labelMedium?.copyWith(
                        color: teal.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.end,
              style: textTheme.titleSmall?.copyWith(
                color: teal.foreground,
                fontWeight: FontWeight.w500,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        if (footer != null)
          Text(footer!, style: MealCountTable._footerStyle(textTheme)),
      ],
    );
    const vertical = AppSpacing.space3 + 2;
    if (row.changed) {
      // Lớp có số đổi do GV sửa điểm danh (NUT-04): dải nền cam lùi vào trong card, chữ vẫn thẳng cột
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space1 + 2,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2 + 2,
          vertical: vertical - 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: body,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: vertical,
      ),
      child: body,
    );
  }
}

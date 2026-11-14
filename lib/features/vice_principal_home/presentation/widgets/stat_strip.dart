import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';

/// Một cột của [StatStrip]: số (có màu) + nhãn chữ.
@immutable
class StatStripItem {
  const StatStripItem({required this.value, required this.label, this.color});

  final String value;
  final String label;

  /// Màu số; null ⇒ `textPrimary`.
  final Color? color;
}

/// Dải số liệu chung một thẻ (Figma PHT 01, PHT 04): các cột chia đều, số luôn kèm nhãn chữ.
/// Số do BE trả; dải chỉ trình bày. Chữ phóng lớn ⇒ xuống 2 cột thay vì ép hẹp.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items, this.tinted = false});

  final List<StatStripItem> items;

  /// Nền `primarySoft` viền `primaryBorder` (thẻ tổng số suất) thay nền trắng.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final columns = large && items.length > 2 ? 2 : items.length;
    final rows = [
      for (var i = 0; i < items.length; i += columns)
        items.sublist(i, (i + columns).clamp(0, items.length)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: tinted ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: tinted ? AppColors.primaryBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++)
                  Expanded(
                    child: j < row.length
                        ? _StatCell(item: row[j])
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.item});

  final StatStripItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '${item.label}: ${item.value}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.value,
                maxLines: 1,
                style: textTheme.headlineSmall?.copyWith(
                  color: item.color ?? AppColors.textPrimary,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

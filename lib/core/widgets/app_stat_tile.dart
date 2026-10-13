import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';

/// Ô số liệu: số lớn + nhãn, nền theo tông trạng thái (DESIGN.md §6.1).
/// Số luôn đi kèm nhãn chữ ⇒ không truyền nghĩa chỉ bằng màu.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.value,
    required this.label,
    this.tone,
  });

  final String value;
  final String label;

  /// Không có tông ⇒ ô trắng viền nhạt.
  final AppStatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = tone == null
        ? null
        : AppStatusColors.of(context).tone(tone!);
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: colors?.background ?? AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors?.border ?? AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: colors?.foreground ?? AppColors.textPrimary,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: colors?.foreground ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hàng ô số liệu chia đều; chữ phóng lớn ⇒ xuống lưới 2 cột thay vì ép hẹp.
class AppStatRow extends StatelessWidget {
  const AppStatRow({super.key, required this.tiles});

  final List<AppStatTile> tiles;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (large && tiles.length > 2) {
      return Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: [
          for (final tile in tiles)
            FractionallySizedBox(widthFactor: 0.48, child: tile),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.space2),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

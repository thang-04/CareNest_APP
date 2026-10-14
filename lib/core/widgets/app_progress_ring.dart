import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/theme/app_text_styles.dart';

/// Vòng tiến độ có số ở giữa (vd. "0/28" đã điểm danh, "93%" có mặt).
/// Tỉ lệ và chữ do màn truyền từ số BE trả; vòng chỉ vẽ, không tự tính nghiệp vụ.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.value,
    required this.label,
    required this.caption,
    this.color,
    this.size = 88,
  });

  /// 0–1.
  final double value;

  /// Chữ lớn ở giữa, vd. "0/28".
  final String label;

  /// Chữ nhỏ dưới số, vd. "đã điểm danh".
  final String caption;

  /// Màu cung; null ⇒ `primary`.
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label $caption',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: size * 0.1,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.track,
              color: color ?? AppColors.primary,
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium?.copyWith(
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                    Text(
                      caption,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

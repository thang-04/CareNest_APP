import 'package:flutter/material.dart';

import 'package:carenest_app/core/constants/sizes.dart';
import 'package:carenest_app/core/widgets/app_photo_placeholder.dart';

/// Ô ảnh trong thẻ một bữa (đề xuất A, user 17/11): ô tự đổi theo số ảnh —
/// 1 ảnh là một ô rộng, 2 ảnh hai ô, 3 ảnh ba ô vuông, từ 4 ảnh thì ô thứ ba ghi "+n".
/// Chạm ô nào thì [onOpen] nhận vị trí ảnh đó (ô "+n" mở từ ảnh thứ ba).
class MealPhotoGrid extends StatelessWidget {
  const MealPhotoGrid({
    super.key,
    required this.mealName,
    required this.count,
    required this.onOpen,
  });

  /// Tên bữa như trong thực đơn, vd. "Bữa sáng".
  final String mealName;
  final int count;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final meal = mealName.isEmpty
        ? mealName
        : mealName[0].toLowerCase() + mealName.substring(1);

    Widget tile(int index, {required double aspectRatio, int more = 0}) {
      return Semantics(
        container: true,
        button: true,
        label: count == 1
            ? 'Xem ảnh $meal'
            : 'Xem ảnh ${index + 1} trong $count của $meal',
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => onOpen(index),
            child: AppPhotoPlaceholder(
              aspectRatio: aspectRatio,
              moreCount: more,
            ),
          ),
        ),
      );
    }

    if (count == 1) return tile(0, aspectRatio: 16 / 9);
    final shown = count > 3 ? 3 : count;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: tile(
              i,
              aspectRatio: count == 2 ? 4 / 3 : 1,
              // Ô thứ ba đại diện cho ảnh 3…n
              more: count > 3 && i == 2 ? count - 2 : 0,
            ),
          ),
        ],
      ],
    );
  }
}

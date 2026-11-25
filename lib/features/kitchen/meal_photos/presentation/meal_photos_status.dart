import 'package:flutter/widgets.dart';

import 'package:carenest_app/core/constants/app_icons.dart';
import 'package:carenest_app/core/constants/colors.dart';
import 'package:carenest_app/core/theme/app_status_colors.dart';
import 'package:carenest_app/features/kitchen/meal_photos/domain/kitchen_meal_photos.dart';

/// Nhãn, tông, màu của ảnh mẫu bữa ăn. Màu không đứng một mình: thẻ bữa luôn có nhãn chữ.
abstract final class MealPhotosStatus {
  static (String, AppStatusTone, IconData?) badge(
    SampleMeal meal,
  ) => switch (meal.status) {
    MealPhotoStatus.done => ('Đã có ảnh', AppStatusTone.green, AppIcons.check),
    MealPhotoStatus.needed => (
      'Cần chụp',
      AppStatusTone.orange,
      AppIcons.camera,
    ),
    MealPhotoStatus.upcoming => (
      'Chưa tới giờ',
      AppStatusTone.gray,
      AppIcons.clock,
    ),
    MealPhotoStatus.missed => (
      'Quá giờ, chưa có ảnh',
      AppStatusTone.red,
      AppIcons.alertTriangle,
    ),
    MealPhotoStatus.noWindow => ('Chưa có giờ đăng', AppStatusTone.gray, null),
  };

  /// Vạch tiến độ trên ô nhóm và chấm dòng thời gian
  static Color color(MealPhotoStatus status) => switch (status) {
    MealPhotoStatus.done => AppColors.toneGreen,
    MealPhotoStatus.needed => AppColors.toneOrange,
    MealPhotoStatus.missed => AppColors.toneRed,
    MealPhotoStatus.upcoming ||
    MealPhotoStatus.noWindow => AppColors.borderStrong,
  };

  /// "bữa trưa" — tên buổi đặt giữa câu
  static String inSentence(SampleMeal meal) => meal.name.toLowerCase();
}

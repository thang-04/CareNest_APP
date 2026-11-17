import 'package:flutter/foundation.dart';

/// Khung giờ đăng ảnh của một bữa (NUT-16: HT cấu hình, chung toàn trường; ngoài khung thì chặn).
/// Nguồn dữ liệu trả, App không tự tính theo giờ máy.
enum PhotoWindow { upcoming, open, closed }

/// Một bữa của một nhóm tuổi hôm nay. Bếp chụp bao nhiêu ảnh cũng được, mỗi bữa cần ít nhất
/// 1 ảnh (user 17/11). Ảnh thật tải qua URL có auth khi có API.
@immutable
class SampleMeal {
  const SampleMeal({
    required this.id,
    required this.name,
    required this.time,
    required this.windowLabel,
    required this.window,
    this.photoIds = const [],
  });

  /// Buổi theo BE MealPhoto.session: MORNING, LUNCH, AFTERNOON
  final String id;

  /// "Bữa sáng"
  final String name;

  /// Giờ ăn, "07:45"
  final String time;

  /// Khung giờ đăng, "07:30–08:30"
  final String windowLabel;
  final PhotoWindow window;
  final List<String> photoIds;
}

/// Các bữa một nhóm tuổi ăn trong ngày: số bữa theo nhóm tuổi do nhà trường cấu hình
/// (user 17/11: "hiệu trưởng cấu hình"; BE NUT-17 ghi PHT phụ trách dinh dưỡng).
@immutable
class AgeGroupMeals {
  const AgeGroupMeals({
    required this.id,
    required this.label,
    required this.ageRange,
    required this.meals,
  });

  final String id;

  /// "Mầm"
  final String label;

  /// "3–4 tuổi"
  final String ageRange;
  final List<SampleMeal> meals;
}

/// Ảnh mẫu hôm nay của bếp một điểm trường, theo nhóm tuổi (BE chưa có API theo nhóm tuổi).
@immutable
class KitchenPhotoDay {
  const KitchenPhotoDay({
    required this.date,
    required this.kitchenLabel,
    required this.groups,
  });

  final DateTime date;

  /// "Bếp cơ sở chính"
  final String kitchenLabel;
  final List<AgeGroupMeals> groups;
}

abstract interface class KitchenPhotoSource {
  Future<KitchenPhotoDay> loadToday();

  /// Đăng thêm 1 ảnh cho bữa [mealId] của nhóm [groupId]; trả ngày đã cập nhật.
  Future<KitchenPhotoDay> addPhoto({
    required String groupId,
    required String mealId,
  });
}

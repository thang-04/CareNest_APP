import 'package:flutter/foundation.dart';

@immutable
class MenuMeal {
  const MenuMeal({
    required this.name,
    required this.time,
    required this.dishes,
  });

  /// "Bữa sáng"
  final String name;

  /// "07:45"
  final String time;
  final String dishes;
}

/// Ảnh bữa ăn GV đăng khi nhận suất (quyết định 8, PROPOSED); ảnh thật tải qua URL có auth.
@immutable
class MealPhotoSet {
  const MealPhotoSet({
    required this.postedBy,
    required this.postedAt,
    required this.slots,
  });

  final String postedBy;
  final DateTime postedAt;

  /// Nhãn từng ảnh, vd. "Bữa trưa".
  final List<String> slots;
}

/// Thực đơn một ngày đã công bố (NUT-08) cho một bé. Năng lượng và ghi chú dị ứng là chữ BE trả,
/// APP không tự tính hay so chuẩn (NUT-06, NUT-09).
@immutable
class MenuDay {
  const MenuDay({
    required this.date,
    required this.meals,
    this.energyNote,
    this.allergyNote,
    this.allergyAlert = false,
    this.photos,
  });

  final DateTime date;
  final List<MenuMeal> meals;
  final String? energyNote;
  final String? allergyNote;

  /// Bé có thực đơn thay thế ⇒ nhắc kiểu cảnh báo thay vì xác nhận.
  final bool allergyAlert;
  final MealPhotoSet? photos;
}

@immutable
class WeeklyMenu {
  const WeeklyMenu({required this.weekStart, required this.days});

  final DateTime weekStart;
  final List<MenuDay> days;
}

abstract interface class WeeklyMenuSource {
  Future<WeeklyMenu> loadWeek(String childId);
}

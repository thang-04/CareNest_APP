import 'package:flutter/foundation.dart';

@immutable
class MenuMeal {
  const MenuMeal({
    required this.name,
    required this.time,
    required this.dishes,
    this.photos,
  });

  /// "Bữa sáng"
  final String name;

  /// "07:45"
  final String time;
  final String dishes;

  /// Ảnh mẫu của bữa cho nhóm tuổi của bé; null ⇒ ngày đó không có phần ảnh.
  final MealPhotos? photos;
}

/// Ảnh mẫu một bữa theo nhóm tuổi của bé, bếp chụp (NUT-16); một bữa có thể nhiều ảnh
/// (đề xuất A, user 17/11). BE chưa có API theo nhóm tuổi ⇒ dữ liệu giả; ảnh thật tải qua URL có auth.
@immutable
class MealPhotos {
  const MealPhotos.posted({
    required this.ageGroup,
    required this.postedAt,
    required this.photoIds,
  });

  /// Nhãn nhóm tuổi, vd. "Mầm".
  final String ageGroup;
  final DateTime postedAt;
  final List<String> photoIds;
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
  });

  final DateTime date;
  final List<MenuMeal> meals;
  final String? energyNote;
  final String? allergyNote;

  /// Bé có thực đơn thay thế ⇒ nhắc kiểu cảnh báo thay vì xác nhận.
  final bool allergyAlert;
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

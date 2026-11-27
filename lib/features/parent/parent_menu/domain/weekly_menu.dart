import 'package:flutter/foundation.dart';

/// Bữa theo BE `MealSession`; nhãn như màn bếp.
enum MenuSession {
  morning('MORNING', 'Bữa phụ sáng'),
  lunch('LUNCH', 'Bữa trưa'),
  afternoon('AFTERNOON', 'Bữa chiều');

  const MenuSession(this.code, this.label);
  final String code;
  final String label;

  static MenuSession? fromCode(Object? code) =>
      values.where((s) => s.code == code).firstOrNull;
}

/// Một món (BE `ParentMenuResponse` PAR-14). [childAllergens] = chất trong món mà bé đã khai dị ứng,
/// BE đối chiếu; APP chỉ hiện cảnh báo, không tự so (NUT-23).
@immutable
class MenuDish {
  const MenuDish({
    required this.name,
    this.allergens = const [],
    this.childAllergens = const [],
  });

  final String name;
  final List<String> allergens;
  final List<String> childAllergens;
}

/// Ảnh bữa ăn bếp đăng (NUT-16); tải qua API có auth bằng [photoId].
@immutable
class MenuPhoto {
  const MenuPhoto({required this.photoId, required this.uploadedAt});

  final String photoId;
  final DateTime uploadedAt;
}

@immutable
class MenuMealEntry {
  const MenuMealEntry({
    required this.session,
    required this.dishes,
    this.photo,
  });

  final MenuSession session;
  final List<MenuDish> dishes;

  /// null ⇒ bếp chưa đăng ảnh bữa này.
  final MenuPhoto? photo;
}

/// Một ngày trong tuần của bé. [meals] rỗng khi chưa công bố, ngày nghỉ, bé chưa học hoặc
/// bé không báo ăn — lý do lấy từ cờ BE, APP không tự suy.
@immutable
class MenuDay {
  const MenuDay({
    required this.date,
    required this.meals,
    this.enrolled = true,
    this.dayOff = false,
  });

  final DateTime date;
  final List<MenuMealEntry> meals;
  final bool enrolled;
  final bool dayOff;
}

@immutable
class WeeklyMenu {
  const WeeklyMenu({
    required this.weekStart,
    required this.days,
    this.published = true,
    this.mealsHidden = false,
    this.unmatchedAllergies = const [],
  });

  final DateTime weekStart;
  final List<MenuDay> days;

  /// Tuần đã công bố (NUT-08).
  final bool published;

  /// Bé không báo ăn ⇒ BE ẩn món và ảnh.
  final bool mealsHidden;

  /// Dị ứng bé đã khai nhưng không khớp danh mục chất ⇒ BE không cảnh báo được theo món.
  final List<String> unmatchedAllergies;
}

abstract interface class WeeklyMenuSource {
  /// [weekStart] null ⇒ tuần hiện tại theo BE.
  Future<WeeklyMenu> loadWeek(String childId, {DateTime? weekStart});

  /// Byte ảnh bữa; null ⇒ chỉ có khối giữ chỗ (Xem thử).
  Future<Uint8List?> loadPhoto(String childId, String photoId);
}

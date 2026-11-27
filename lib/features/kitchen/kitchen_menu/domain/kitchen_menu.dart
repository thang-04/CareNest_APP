import 'package:flutter/foundation.dart';

/// Cảnh báo một chất dị ứng của món (NUT-23 25/11: chỉ cảnh báo): số trẻ theo lớp, không tên trẻ (AUTH-05).
@immutable
class DishAllergyWarning {
  const DishAllergyWarning({required this.allergen, required this.byClass});

  /// "Cá"
  final String allergen;

  /// "Mầm 1: 2 trẻ"
  final List<String> byClass;
}

/// Một món trong thực đơn ngày của bếp.
@immutable
class KitchenDish {
  const KitchenDish({
    required this.name,
    this.allergens = const [],
    this.warnings = const [],
  });

  final String name;

  /// Chất dị ứng của món (gộp từ nguyên liệu)
  final List<String> allergens;

  /// Chỉ chất có trẻ dị ứng ở lớp đúng khối, ăn bữa đó
  final List<DishAllergyWarning> warnings;
}

/// Món của một khối trong một bữa (NUT-13: Nhà trẻ khác Mẫu giáo; các lứa Mẫu giáo cùng món).
@immutable
class MenuBlockDishes {
  const MenuBlockDishes({required this.label, required this.dishes});

  /// "Nhà trẻ" / "Mẫu giáo"
  final String label;
  final List<KitchenDish> dishes;
}

/// Một bữa trong thực đơn ngày.
@immutable
class MenuSessionDishes {
  const MenuSessionDishes({
    required this.session,
    required this.label,
    required this.blocks,
  });

  /// BE `MealSession`: MORNING, LUNCH, AFTERNOON
  final String session;

  /// "Bữa trưa"
  final String label;
  final List<MenuBlockDishes> blocks;
}

/// Thực đơn một ngày bếp xem (BE `/nutrition/kitchen/day.menu`): chỉ tuần đã công bố (NUT-08), kèm
/// cảnh báo dị ứng theo món (NUT-23, BE G94-494).
@immutable
class KitchenMenuDay {
  const KitchenMenuDay({
    required this.date,
    required this.published,
    required this.sessions,
    this.unmatched = const [],
    this.isDayOff = false,
  });

  final DateTime date;

  /// Tuần đã công bố; chưa công bố ⇒ không có món
  final bool published;
  final List<MenuSessionDishes> sessions;

  /// Dị ứng đã khai nhưng không khớp danh mục chất: "Hạt điều — Mầm 1: 1 trẻ"
  final List<String> unmatched;
  final bool isDayOff;

  /// Có món nào trong ngày có trẻ dị ứng (Trang chủ bếp nhắc 1 dòng).
  bool get hasWarnings =>
      unmatched.isNotEmpty ||
      sessions.any(
        (s) => s.blocks.any((b) => b.dishes.any((d) => d.warnings.isNotEmpty)),
      );
}

abstract interface class KitchenMenuSource {
  /// Thực đơn ngày [date]; null ⇒ hôm nay theo máy chủ.
  Future<KitchenMenuDay> loadDay([DateTime? date]);
}

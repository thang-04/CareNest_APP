import 'package:flutter/foundation.dart';

/// Món của một khối trong một bữa (NUT-13: Nhà trẻ khác Mẫu giáo; các lứa Mẫu giáo cùng món).
@immutable
class MenuBlockDishes {
  const MenuBlockDishes({required this.label, required this.dishes});

  /// "Nhà trẻ" / "Mẫu giáo"
  final String label;
  final List<String> dishes;
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

/// Thực đơn một ngày bếp xem (BE `/nutrition/kitchen/day.menu`): chỉ tuần đã công bố (NUT-08).
/// Món thay thế theo món (NUT-23) BE chưa có — chờ BE (đề xuất Thắng mục 3).
@immutable
class KitchenMenuDay {
  const KitchenMenuDay({
    required this.date,
    required this.published,
    required this.sessions,
    this.isDayOff = false,
  });

  final DateTime date;

  /// Tuần đã công bố; chưa công bố ⇒ không có món
  final bool published;
  final List<MenuSessionDishes> sessions;
  final bool isDayOff;
}

abstract interface class KitchenMenuSource {
  /// Thực đơn ngày [date]; null ⇒ hôm nay theo máy chủ.
  Future<KitchenMenuDay> loadDay([DateTime? date]);
}

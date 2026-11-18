import 'package:flutter/foundation.dart';

/// Bữa trong ngày, mã theo BE `MealSession`; nhãn như Web (`mealSessions.js`).
enum MealSession {
  morning('MORNING', 'Bữa phụ sáng', 'Sáng'),
  lunch('LUNCH', 'Bữa trưa', 'Trưa'),
  afternoon('AFTERNOON', 'Bữa chiều', 'Chiều');

  const MealSession(this.code, this.label, this.shortLabel);

  final String code;
  final String label;

  /// Nhãn ngắn cho ô chọn bữa.
  final String shortLabel;
}

/// `KitchenDayResponse.menuStatus`.
enum KitchenMenuStatus { none, draft, published }

/// `KitchenDayResponse.countStatus` — bếp chỉ thấy số đã xác nhận (NUT-02, NUT-03).
enum KitchenCountStatus {
  none('Chưa có suất đã xác nhận'),
  partial('Mới xác nhận một số bữa'),
  confirmed('Đã xác nhận');

  const KitchenCountStatus(this.label);

  final String label;
}

/// `FoodNeed.storage`: FRESH / DRY (NUT-10).
enum FoodStorage {
  fresh('Hàng tươi'),
  dry('Hàng khô');

  const FoodStorage(this.label);

  final String label;
}

/// Khối thực đơn (BE `MenuBlock`, NUT-13): nhà trẻ khác món mẫu giáo.
enum MenuBlock {
  nursery('Nhà trẻ'),
  kindergarten('Mẫu giáo');

  const MenuBlock(this.label);

  final String label;
}

/// Nhóm tuổi — `GET /age-groups` (`AgeGroupDetailResponse`, bếp đọc được): `mealSessions`
/// do PHT dinh dưỡng cấu hình (NUT-17). Khối suy như BE `MenuBlock.ofAgeGroup` (`ageToMonths` ≤ 36 ⇒ Nhà trẻ).
@immutable
class KitchenAgeGroup {
  const KitchenAgeGroup({
    required this.id,
    required this.name,
    required this.block,
    required this.sessions,
  });

  final int id;

  /// "Mầm"
  final String name;
  final MenuBlock block;
  final List<MealSession> sessions;
}

/// Nguyên liệu của món cho một nhóm tuổi — `DishDetailResponse.Ingredient`
/// (gam/trẻ theo nhóm tuổi, NUT-18).
@immutable
class DishIngredient {
  const DishIngredient({
    required this.foodName,
    required this.ageGroupId,
    required this.gramsPerChild,
  });

  final String foodName;
  final int ageGroupId;
  final num gramsPerChild;
}

@immutable
class MenuDish {
  const MenuDish({
    required this.id,
    required this.name,
    this.ingredients = const [],
  });

  final int id;
  final String name;
  final List<DishIngredient> ingredients;

  List<DishIngredient> ingredientsFor(int ageGroupId) => ingredients
      .where((item) => item.ageGroupId == ageGroupId && item.gramsPerChild > 0)
      .toList();
}

/// Món một bữa của một khối (Nhà trẻ / Mẫu giáo — NUT-13).
@immutable
class SessionMenu {
  const SessionMenu({
    required this.session,
    required this.block,
    required this.dishes,
  });

  final MealSession session;
  final MenuBlock block;
  final List<MenuDish> dishes;
}

/// Suất đã xác nhận của một lớp, một bữa. Không tên trẻ (AUTH-05).
@immutable
class ClassServings {
  const ClassServings({
    required this.session,
    required this.classroomId,
    required this.classroomName,
    required this.normal,
    required this.substitute,
    this.ageGroupId,
  });

  final MealSession session;
  final int classroomId;
  final String classroomName;

  /// `KitchenDayResponse.ClassServings` chưa có; ghép từ `/meal-counts` (`Line.ageGroupId`).
  final int? ageGroupId;
  final int normal;
  final int substitute;
}

/// Thực phẩm cần cho ngày; số lượng BE tính (NUT-07), APP chỉ hiển thị.
@immutable
class FoodNeed {
  const FoodNeed({
    required this.name,
    required this.unit,
    required this.storage,
    required this.quantity,
  });

  final String name;
  final String unit;
  final FoodStorage storage;
  final num quantity;
}

/// Bếp hôm nay — khớp `GET /nutrition/kitchen/day` (`KitchenDayResponse`).
@immutable
class KitchenDay {
  const KitchenDay({
    required this.date,
    required this.dayOff,
    required this.menuStatus,
    required this.countStatus,
    required this.menu,
    required this.servings,
    required this.foods,
    this.ageGroups = const [],
    this.confirmedAt,
  });

  final List<KitchenAgeGroup> ageGroups;

  final DateTime date;
  final bool dayOff;
  final KitchenMenuStatus menuStatus;
  final KitchenCountStatus countStatus;
  final DateTime? confirmedAt;
  final List<SessionMenu> menu;
  final List<ClassServings> servings;
  final List<FoodNeed> foods;

  /// Các bữa đã có suất xác nhận, theo thứ tự trong ngày.
  List<MealSession> get servedSessions => MealSession.values
      .where((session) => servings.any((row) => row.session == session))
      .toList();

  List<ClassServings> servingsOf(MealSession session) =>
      servings.where((row) => row.session == session).toList();

  /// Món một bữa của khối mà nhóm tuổi thuộc về.
  List<MenuDish> dishesFor(KitchenAgeGroup group, MealSession session) => [
    for (final item in menu)
      if (item.session == session && item.block == group.block) ...item.dishes,
  ];

  /// Món của bữa (gộp các khối, bỏ trùng) — dùng cho sổ lưu mẫu.
  List<MenuDish> dishesOf(MealSession session) {
    final seen = <int>{};
    return [
      for (final block in menu.where((item) => item.session == session))
        for (final dish in block.dishes)
          if (seen.add(dish.id)) dish,
    ];
  }
}

abstract interface class KitchenDaySource {
  Future<KitchenDay> loadDay();
}

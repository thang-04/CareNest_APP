import 'package:flutter/foundation.dart';

/// Suất một lớp: thường / thay thế. Không có tên trẻ (AUTH-05); ghi chú chỉ ở mức cần cho nấu.
@immutable
class ClassMealCount {
  const ClassMealCount({
    required this.className,
    required this.regular,
    required this.alternative,
    this.note,
    this.changed = false,
  });

  final String className;
  final int regular;
  final int alternative;

  /// "dị ứng hải sản", "ăn chay"
  final String? note;

  /// Lớp có yêu cầu điều chỉnh đang chờ xác nhận lại (NUT-03) ⇒ tô nhẹ dòng.
  final bool changed;
}

/// Suất đã chốt một bữa ở một cơ sở. Chỉ có khi MealCount CONFIRMED (NUT-02);
/// tổng do BE tính (NUT-01), APP không cộng lại.
@immutable
class MealCountSheet {
  const MealCountSheet({
    required this.mealLabel,
    required this.confirmedAt,
    required this.total,
    required this.regular,
    required this.alternative,
    required this.classes,
    this.adjustmentNote,
  });

  /// "Bữa trưa"
  final String mealLabel;
  final DateTime confirmedAt;
  final int total;
  final int regular;
  final int alternative;
  final List<ClassMealCount> classes;

  /// Điều chỉnh sau giờ chốt đang chờ xác nhận (NUT-03, P-04) — bếp chưa nấu theo số này.
  final String? adjustmentNote;
}

abstract interface class KitchenMealsSource {
  /// Null khi bữa chưa được xác nhận: bếp không có số để nấu.
  Future<MealCountSheet?> loadSheet();
}

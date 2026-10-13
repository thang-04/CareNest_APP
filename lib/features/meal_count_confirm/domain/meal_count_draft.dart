import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';

/// Số suất BE tự tổng hợp từ điểm danh (NUT-01), chờ người có quyền xác nhận gửi bếp (NUT-02).
/// Ai xác nhận còn PENDING P-05; mockup giao Phó HT. Mọi tổng do BE tính.
@immutable
class MealCountDraft {
  const MealCountDraft({
    required this.mealLabel,
    required this.date,
    required this.summarizedAt,
    required this.deadline,
    required this.total,
    required this.regular,
    required this.alternative,
    required this.classes,
    this.confirmedAt,
    this.adjustmentNote,
  });

  /// "Bữa trưa"
  final String mealLabel;
  final DateTime date;
  final DateTime summarizedAt;

  /// Giờ chốt (cut-off) BE trả.
  final DateTime deadline;
  final int total;
  final int regular;
  final int alternative;
  final List<ClassMealCount> classes;

  /// Đã xác nhận ⇒ bếp thấy số này (CONFIRMED).
  final DateTime? confirmedAt;

  /// Điều chỉnh sau giờ chốt đang chờ duyệt (NUT-03).
  final String? adjustmentNote;

  bool get confirmed => confirmedAt != null;
}

abstract interface class MealCountConfirmSource {
  Future<MealCountDraft> loadToday();

  /// BE kiểm tra quyền `meal-count:confirm` và trạng thái; không retry tự động.
  Future<MealCountDraft> confirm();
}

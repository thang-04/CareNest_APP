import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/kitchen_meals/domain/kitchen_meals.dart';

/// Số suất BE tự tổng hợp từ điểm danh (NUT-01), PHT xác nhận gửi bếp trên Web (NUT-02, đóng P-05).
/// Trên App BGH chỉ xem (AUTH-21, BE ADR-0026). Mọi tổng do BE tính.
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

  /// Số suất đã đổi sau khi xác nhận, cần xác nhận lại (NUT-03) — câu BE trả.
  final String? adjustmentNote;

  bool get confirmed => confirmedAt != null;
}

/// Chỉ đọc: App không gửi xác nhận (AUTH-21, BE ADR-0026).
abstract interface class MealCountConfirmSource {
  Future<MealCountDraft> loadToday();
}

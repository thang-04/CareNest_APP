import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

/// Trạng thái chuẩn bị bữa (NUT-14 PROPOSED): chờ nấu → đang nấu → sẵn sàng → đã giao.
/// Bếp cập nhật, hệ thống chỉ ghi lại; nấu là bước ngoài hệ thống.
enum CookingStage {
  waiting('Chờ nấu'),
  cooking('Đang nấu'),
  ready('Đã nấu xong'),
  delivered('Đã giao đến các lớp');

  const CookingStage(this.label);

  final String label;
}

@immutable
class MealCooking {
  const MealCooking({
    required this.slot,
    required this.stage,
    this.notes = const {},
  });

  final MealSlot slot;
  final CookingStage stage;

  /// Ghi chú từng bước đã qua / đang ở, vd. waiting → "Đã nhận đủ nguyên liệu · 07:45".
  final Map<CookingStage, String> notes;
}

abstract interface class CookingStatusSource {
  Future<Map<MealSlot, MealCooking>> loadToday();
  Future<MealCooking> advance(MealSlot slot);
}

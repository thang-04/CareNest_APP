import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

export 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

/// Một món của thực đơn đã công bố cần lưu mẫu (NUT-21).
@immutable
class SampleDish {
  const SampleDish({required this.id, required this.slot, required this.dish});

  final String id;
  final MealSlot slot;
  final String dish;

  /// "Bữa trưa · Cá basa sốt cà"
  String get label => '${slot.label} · $dish';
}

/// Dữ liệu mở form sổ lưu mẫu: món theo thực đơn, món gợi ý, giờ lấy mẫu do hệ thống ghi.
@immutable
class SampleLogForm {
  const SampleLogForm({
    required this.dishes,
    required this.sampledAt,
    this.suggestedDishId,
  });

  final List<SampleDish> dishes;
  final DateTime sampledAt;
  final String? suggestedDishId;
}

/// Bản ghi lưu mẫu bếp gửi; PHT dinh dưỡng duyệt (NUT-21).
@immutable
class SampleLogEntry {
  const SampleLogEntry({
    required this.dishId,
    required this.amountAndContainer,
    required this.storageTemperature,
  });

  final String dishId;

  /// "150 g · hộp inox có nắp"
  final String amountAndContainer;

  /// "0–5 °C"
  final String storageTemperature;
}

abstract interface class SampleLogSource {
  Future<SampleLogForm> loadForm();
  Future<void> record(SampleLogEntry entry);
}

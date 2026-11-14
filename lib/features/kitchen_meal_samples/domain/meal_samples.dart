import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

export 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

/// Ảnh mẫu cần chụp mỗi bữa: suất thường và suất thay thế (theo món, không tên trẻ — NUT-23).
enum SampleKind {
  regular('Mẫu suất thường'),
  alternative('Mẫu suất thay thế');

  const SampleKind(this.label);

  final String label;
}

/// Khung giờ được chụp/sửa ảnh của một bữa — HT cấu hình, chung toàn trường; BE chặn ngoài khung (NUT-16).
@immutable
class SampleWindow {
  const SampleWindow({required this.opensAt, required this.closesAt});

  final DateTime opensAt;
  final DateTime closesAt;
}

/// Ảnh mẫu bữa của bếp một cơ sở (NUT-16); phụ huynh xem trong thực đơn ngày (PAR-01).
@immutable
class MealSampleDay {
  const MealSampleDay({
    required this.kitchenLabel,
    required this.date,
    required this.menus,
    required this.windows,
    required this.kinds,
    required this.alternativeCount,
  });

  /// "Bếp cơ sở chính"
  final String kitchenLabel;
  final DateTime date;

  /// Thực đơn đã công bố theo bữa (NUT-08).
  final Map<MealSlot, String> menus;
  final Map<MealSlot, SampleWindow> windows;

  /// Loại ảnh mẫu BE yêu cầu cho bữa.
  final List<SampleKind> kinds;
  final int alternativeCount;
}

abstract interface class MealSampleSource {
  Future<MealSampleDay> loadDay();
  Set<SampleKind> captured(MealSlot slot);
  void capture(MealSlot slot, SampleKind kind);
  Future<void> save(MealSlot slot);
}

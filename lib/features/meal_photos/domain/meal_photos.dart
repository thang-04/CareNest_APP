import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

export 'package:carenest_app/features/school_menu/domain/meal_slot.dart';

/// Ảnh bữa ăn GV chụp khi bếp giao tới lớp rồi đăng cho phụ huynh — quyết định 8 (PROPOSED),
/// BE NUT-16 mới ghi "bếp chụp". Chỉ chụp khay suất ăn, không chụp mặt trẻ.
enum PhotoAudience { wholeClass, alternativeOnly }

@immutable
class MealPhotoDay {
  const MealPhotoDay({
    required this.date,
    required this.className,
    required this.menus,
    required this.regularCount,
    required this.alternativeCount,
    required this.alternativeNote,
    required this.alternativeChild,
    required this.classSize,
    required this.sentNotes,
  });

  final DateTime date;
  final String className;

  /// Thực đơn đã công bố theo bữa (NUT-08).
  final Map<MealSlot, String> menus;
  final int regularCount;
  final int alternativeCount;

  /// "Dị ứng hải sản: chụp riêng"
  final String alternativeNote;

  /// Tên bé có suất thay thế (gửi riêng phụ huynh bé này).
  final String alternativeChild;
  final int classSize;

  /// Bữa đã gửi ⇒ "đã gửi 07:55 · 21/28 phụ huynh đã xem".
  final Map<MealSlot, String> sentNotes;
}

abstract interface class MealPhotoSource {
  Future<MealPhotoDay> loadDay(String classId);
  int capturedCount(MealSlot slot);
  void capture(MealSlot slot);
  Future<void> send(MealSlot slot, PhotoAudience audience, String message);
}

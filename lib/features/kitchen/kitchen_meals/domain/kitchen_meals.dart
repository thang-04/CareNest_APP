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

  /// "dị ứng hải sản", "ăn chay" — BE `ClassServings` chưa có, chỉ màn debug Phó HT dùng
  final String? note;

  /// Lớp có yêu cầu điều chỉnh đang chờ xác nhận lại (NUT-03) ⇒ tô nhẹ dòng.
  final bool changed;
}

/// Suất đã xác nhận một bữa theo lớp (BE `KitchenDayResponse.servings` của một buổi).
/// Tổng do nguồn dữ liệu trả (NUT-01), APP không cộng lại.
@immutable
class SessionMealCount {
  const SessionMealCount({
    required this.session,
    required this.label,
    required this.total,
    required this.regular,
    required this.alternative,
    required this.classes,
    this.blockNote,
  });

  /// Buổi theo BE MealSession: MORNING, LUNCH, AFTERNOON
  final String session;

  /// "Bữa phụ sáng"
  final String label;
  final int total;
  final int regular;
  final int alternative;
  final List<ClassMealCount> classes;

  /// "Nhà trẻ" khi chỉ một khối ăn bữa này
  final String? blockNote;
}

/// Suất đã chốt các bữa trong ngày ở một cơ sở. Chỉ bữa đã xác nhận (NUT-02);
/// số đang chờ xác nhận lại không hiện (NUT-03).
@immutable
class MealCountSheet {
  const MealCountSheet({required this.confirmedAt, required this.sessions});

  final DateTime confirmedAt;
  final List<SessionMealCount> sessions;
}

abstract interface class KitchenMealsSource {
  /// Null khi chưa bữa nào được xác nhận: bếp không có số để nấu.
  Future<MealCountSheet?> loadSheet();
}

import 'package:flutter/foundation.dart';

/// Việc bếp ghi trên App (AUTH-21): ảnh mẫu (NUT-16), lưu mẫu và hủy mẫu (NUT-21).
enum KitchenTaskKind { mealPhotos, foodSamples, sampleDisposal }

/// Mức của việc: cần làm / quá giờ còn thiếu / chờ PHT duyệt / đến hạn / đã xong / chưa tới giờ.
enum KitchenTaskLevel { todo, missed, waiting, due, done, later }

@immutable
class KitchenTask {
  const KitchenTask({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.level,
  });

  final KitchenTaskKind kind;
  final String title;
  final String subtitle;
  final String badge;
  final KitchenTaskLevel level;
}

/// Trạng thái số suất trong ngày theo BE `KitchenDayResponse.countStatus`.
enum KitchenCountStatus { none, partial, confirmed }

/// Số suất đã xác nhận một bữa. Tổng và số thay thế do nguồn dữ liệu trả (BE NUT-01), App không cộng.
@immutable
class SessionServings {
  const SessionServings({
    required this.session,
    required this.label,
    required this.total,
    required this.substitute,
    this.blockNote,
  });

  /// Buổi theo BE MealSession: MORNING, LUNCH, AFTERNOON
  final String session;

  /// "Bữa phụ sáng"
  final String label;
  final int total;
  final int substitute;

  /// "Nhà trẻ" khi chỉ một khối ăn bữa này (NUT-13, cấu hình nhóm tuổi của HT)
  final String? blockNote;
}

/// Trang chủ bếp theo BE `GET /nutrition/kitchen/day` (canvas "Trang chủ bếp (theo BE)").
@immutable
class KitchenToday {
  const KitchenToday({
    required this.date,
    required this.campusLabel,
    required this.countStatus,
    required this.servings,
    required this.tasks,
    this.confirmedAt,
    this.isDayOff = false,
  });

  final DateTime date;

  /// "Cơ sở chính" — tài khoản bếp gắn một điểm trường (AUTH-22)
  final String campusLabel;
  final KitchenCountStatus countStatus;

  /// Chỉ bữa đã xác nhận (NUT-02); số đang chờ xác nhận lại không hiện (NUT-03)
  final List<SessionServings> servings;
  final DateTime? confirmedAt;
  final List<KitchenTask> tasks;
  final bool isDayOff;
}

abstract interface class KitchenHomeSource {
  Future<KitchenToday> loadToday();
}

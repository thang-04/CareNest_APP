import 'package:flutter/foundation.dart';

/// Vòng đời theo ATT-05 (CONFIRMED): `SUBMITTED → CANCELLED`, không có bước duyệt.
enum LeaveNoticeStatus { submitted, cancelled }

/// Buổi nghỉ — BE `LeavePart` (FULL_DAY / MORNING / AFTERNOON, ATT-12); nửa buổi chỉ cho đơn 1 ngày.
enum LeaveSession { fullDay, morning, afternoon }

/// Bữa ăn — BE `MealSession` (MORNING / LUNCH / AFTERNOON).
enum LeaveMeal { morningSnack, lunch, afternoonSnack }

/// Bữa của ngày nghỉ nửa buổi theo nhóm tuổi của bé, do BE chia (ATT-12): [offMeals] thuộc
/// buổi nghỉ (huỷ), [keptMeals] thuộc buổi còn học (theo lựa chọn "Bé tham gia ăn").
@immutable
class LeaveMealPlan {
  const LeaveMealPlan({required this.offMeals, required this.keptMeals});

  final List<LeaveMeal> offMeals;
  final List<LeaveMeal> keptMeals;
}

@immutable
class LeaveNotice {
  const LeaveNotice({
    required this.id,
    required this.childId,
    required this.from,
    required this.to,
    required this.session,
    required this.reason,
    required this.status,
    this.seenByTeacher = false,
    this.eats,
    this.eatsMeals = const [],
  });

  final String id;
  final String childId;
  final DateTime from;
  final DateTime to;
  final LeaveSession session;
  final String reason;
  final LeaveNoticeStatus status;

  /// Giáo viên đã xem/ghi nhận (ATT-05: GV chỉ xem, không duyệt) — BE trả.
  final bool seenByTeacher;

  /// BE `eats`: null = không áp dụng (cả ngày, hoặc buổi còn học không có bữa).
  final bool? eats;

  /// BE `eatsMeals`: các bữa của buổi còn học.
  final List<LeaveMeal> eatsMeals;
}

/// Dữ liệu phụ huynh nhập; BE kiểm tra lại mọi thứ (ngày qua cut-off, quyền — ATT-05b, AUTH-04).
@immutable
class LeaveNoticeDraft {
  const LeaveNoticeDraft({
    required this.childId,
    required this.from,
    required this.to,
    required this.session,
    required this.reason,
    this.eats,
  });

  final String childId;
  final DateTime from;
  final DateTime to;
  final LeaveSession session;
  final String reason;

  /// Công tắc "Bé tham gia ăn" của đơn nửa buổi; null với đơn cả ngày.
  final bool? eats;
}

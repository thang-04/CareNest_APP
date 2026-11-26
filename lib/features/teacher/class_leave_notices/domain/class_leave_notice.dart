import 'package:flutter/foundation.dart';

/// Trạng thái đơn — khớp BE `LeaveRequestStatus`; nhãn như Web (`LEAVE_STATUS_LABELS`).
enum LeaveRequestStatus {
  active('ACTIVE', 'Đang hiệu lực'),
  cancelled('CANCELLED', 'Đã hủy');

  const LeaveRequestStatus(this.code, this.label);
  final String code;
  final String label;
}

/// Buổi nghỉ — khớp BE `LeavePart`; nhãn như Web `LEAVE_PART_LABELS`.
enum LeavePart {
  fullDay('FULL_DAY', 'Cả ngày'),
  morning('MORNING', 'Buổi sáng'),
  afternoon('AFTERNOON', 'Buổi chiều');

  const LeavePart(this.code, this.label);
  final String code;
  final String label;
}

/// Nhãn bữa như Web `MEAL_SESSION_LABELS`; mã lạ giữ nguyên.
String mealSessionLabel(String code) => switch (code) {
  'MORNING' => 'Bữa phụ sáng',
  'LUNCH' => 'Bữa trưa',
  'AFTERNOON' => 'Bữa chiều',
  _ => code,
};

/// Khoảng ngày mặc định của danh sách: từ đầu tháng tới 60 ngày sau (BE mặc định chỉ trả tháng hiện
/// tại; kéo dài để thấy đơn báo trước). Nguồn Live và bộ lọc của màn dùng chung mốc này.
(DateTime, DateTime) defaultLeaveRange(DateTime today) => (
  DateTime(today.year, today.month),
  DateTime(today.year, today.month, today.day + 60),
);

/// Đơn nghỉ của trẻ trong lớp — tập con field BE `LeaveRequestResponse`.
/// GV chỉ xem, không duyệt, không tạo thay phụ huynh (ATT-05).
@immutable
class ClassLeaveEntry {
  const ClassLeaveEntry({
    required this.id,
    required this.childId,
    required this.childName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.createdByName,
    required this.createdAt,
    this.className = '',
    this.part = LeavePart.fullDay,
    this.eats,
    this.eatsMeals = const [],
    this.noticeOnly = false,
    this.effectiveTo,
    this.cancelledAt,
    this.appliedDates = const [],
    this.skippedDates = const [],
  });

  final String id;
  final String childId;
  final String childName;
  final DateTime fromDate;
  final DateTime toDate;
  final String className;
  final LeavePart part;

  /// Trẻ có ăn bữa của buổi còn học không; null = không áp dụng (cả ngày / không có bữa).
  final bool? eats;
  final List<String> eatsMeals;

  /// Báo nghỉ chiều sau giờ chốt: không đổi điểm danh/suất ăn (BE `noticeOnly`).
  final bool noticeOnly;

  /// Ngày cuối còn hiệu lực khi phụ huynh hủy một phần (BE giữ ACTIVE).
  final DateTime? effectiveTo;
  final String reason;
  final LeaveRequestStatus status;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  /// Ngày đã ghi Vắng có phép; ngày bị bỏ qua vì đã quá giờ khóa (ATT-05b).
  final List<DateTime> appliedDates;
  final List<DateTime> skippedDates;
}

/// BE: `GET /leave-requests?classId=&from=&to=` (quyền ATTENDANCE_VIEW).
abstract interface class ClassLeaveSource {
  /// [from]/[to] null ⇒ [defaultLeaveRange] của hôm nay.
  Future<List<ClassLeaveEntry>> load(
    String classId, {
    DateTime? from,
    DateTime? to,
  });
}

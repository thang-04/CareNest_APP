import 'package:flutter/foundation.dart';

/// Trạng thái đơn — khớp BE `LeaveRequestStatus`; nhãn như Web (`LEAVE_STATUS_LABELS`).
enum LeaveRequestStatus {
  active('ACTIVE', 'Đang hiệu lực'),
  cancelled('CANCELLED', 'Đã hủy');

  const LeaveRequestStatus(this.code, this.label);
  final String code;
  final String label;
}

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
  Future<List<ClassLeaveEntry>> load(String classId);
}

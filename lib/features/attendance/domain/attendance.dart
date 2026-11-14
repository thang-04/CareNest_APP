import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/attendance/domain/arrival_health.dart';

/// Lớp được phân công (AUTH-03) — danh sách do BE trả.
@immutable
class ClassSummary {
  const ClassSummary({
    required this.id,
    required this.name,
    required this.campusName,
    required this.childCount,
  });

  final String id;
  final String name;
  final String campusName;
  final int childCount;
}

/// Trạng thái điểm danh một trẻ (ATT-01). Mã thật theo hợp đồng BE khi có endpoint.
/// `excused` chỉ do đơn nghỉ đặt, GV không tự chọn (ATT-09).
enum AttendanceStatus { present, excused, unexcused, notRecorded }

/// Một dòng nhập: điểm danh + sức khỏe đầu ngày (HLT-07). Có mặt là ăn đủ các bữa, không báo ăn riêng (ATT-02).
@immutable
class KidAttendance {
  const KidAttendance({
    required this.childId,
    required this.fullName,
    required this.status,
    this.health = const ArrivalHealth(),
    this.note,
    this.hasLeaveNotice = false,
  });

  final String childId;
  final String fullName;
  final AttendanceStatus status;

  /// Sức khỏe đầu ngày; chỉ bé có mặt mới có (BE `HEALTH_CHILD_NOT_PRESENT`).
  final ArrivalHealth health;

  /// Ghi chú BE trả dưới tên: đơn nghỉ, dị ứng.
  final String? note;

  /// Có đơn nghỉ hôm nay ⇒ BE khóa ở Vắng có phép, GV không đổi được (ATT-04).
  final bool hasLeaveNotice;

  KidAttendance copyWith({AttendanceStatus? status, ArrivalHealth? health}) {
    return KidAttendance(
      childId: childId,
      fullName: fullName,
      status: status ?? this.status,
      health: health ?? this.health,
      note: note,
      hasLeaveNotice: hasLeaveNotice,
    );
  }
}

@immutable
class AttendanceSheet {
  const AttendanceSheet({
    required this.classSummary,
    required this.date,
    required this.kids,
    this.lockAt,
    this.isSchoolDay = true,
  });

  final ClassSummary classSummary;
  final DateTime date;
  final List<KidAttendance> kids;

  /// BE `DayInfoResponse.schoolDay`: ngày nghỉ theo lịch trường không điểm danh (ATT-06, SCH-05, đóng P-19).
  final bool isSchoolDay;

  /// Giờ khoá nhập BE trả (cut-off P-03 PENDING); APP chỉ hiển thị, không tự khoá theo giờ máy.
  final String? lockAt;
}

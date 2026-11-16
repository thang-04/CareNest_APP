import 'package:flutter/foundation.dart';

/// Con có GuardianLink với phụ huynh (AUTH-04) — danh sách do BE trả.
@immutable
class ChildSummary {
  const ChildSummary({
    required this.id,
    required this.fullName,
    required this.shortName,
    required this.className,
    required this.campusName,
    required this.ageLabel,
    required this.homeroomTeacher,
  });

  final String id;
  final String fullName;
  final String shortName;
  final String className;
  final String campusName;

  /// "4 tuổi" — BE trả, APP không tự tính từ ngày sinh.
  final String ageLabel;

  /// Tên gọi ngắn của giáo viên chủ nhiệm, vd. "Cô Hà".
  final String homeroomTeacher;
}

/// Trạng thái điểm danh hôm nay theo dữ liệu BE; APP không tự suy.
enum ParentAttendanceStatus {
  present,
  absentExcused,
  absentUnexcused,
  notRecorded,
}

/// Tóm tắt hôm nay của một con (mockup P02). Field cụ thể chờ P-13b ⇒ chỉ hiển thị field có trong dữ liệu.
@immutable
class ParentToday {
  const ParentToday({
    required this.greetingName,
    required this.date,
    required this.child,
    required this.attendance,
    required this.unreadNotifications,
    this.arrivedAt,
    this.menuPublished = false,
    this.activityTitle,
  });

  /// "Chị Nguyễn Thu Lan"
  final String greetingName;
  final DateTime date;
  final ChildSummary child;
  final ParentAttendanceStatus attendance;
  final DateTime? arrivedAt;
  final int unreadNotifications;

  /// Chỉ thực đơn đã công bố mới có (NUT-08).
  final bool menuPublished;

  /// Tên hoạt động chính trong ngày; null khi chưa có (OBS-07 OPEN).
  final String? activityTitle;
}

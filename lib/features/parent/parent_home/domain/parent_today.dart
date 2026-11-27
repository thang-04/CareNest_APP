import 'package:flutter/foundation.dart';

/// Con có GuardianLink với phụ huynh (AUTH-04) — danh sách do BE trả.
@immutable
class ChildSummary {
  const ChildSummary({
    required this.id,
    required this.fullName,
    required this.shortName,
    required this.className,
    this.campusName,
    this.ageLabel,
    this.homeroomTeacher,
  });

  final String id;
  final String fullName;
  final String shortName;
  final String className;

  /// BE `/children/{id}/profile` chưa trả tên điểm trường, nhãn tuổi, tên GV chủ nhiệm ⇒ null, màn ẩn (user 25/11).
  final String? campusName;

  /// "4 tuổi" — BE trả, APP không tự tính từ ngày sinh.
  final String? ageLabel;

  /// Tên gọi ngắn của giáo viên chủ nhiệm, vd. "Cô Hà".
  final String? homeroomTeacher;

  /// "Mầm 3A · 4 tuổi" — bỏ phần BE chưa trả.
  String get classAndAge => [className, ?ageLabel].join(' · ');

  /// "Mầm 3A · Cơ sở chính" — bỏ phần BE chưa trả.
  String get classAndCampus => [className, ?campusName].join(' · ');
}

/// Trạng thái điểm danh hôm nay theo dữ liệu BE; APP không tự suy.
/// BE `ParentAttendanceStatus` (Cần chốt 24/11): thêm không phải ngày học, bé chưa vào lớp / đã nghỉ học.
enum ParentAttendanceStatus {
  present,
  absentExcused,
  absentUnexcused,
  notRecorded,
  noSchool,
  notEnrolled,
}

/// Buổi nghỉ theo đơn nửa buổi (BE `DayPart`, ATT-12).
enum AbsentPart { morning, afternoon }

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
    this.absentPart,
    this.afternoonNoticeSent = false,
    this.menuPublished = false,
    this.activityTitle,
  });

  /// "Chị Nguyễn Thu Lan"
  final String greetingName;
  final DateTime date;
  final ChildSummary child;
  final ParentAttendanceStatus attendance;
  final DateTime? arrivedAt;

  /// Nghỉ một buổi theo đơn (null = không nghỉ nửa buổi).
  final AbsentPart? absentPart;

  /// Hôm nay có đơn nghỉ chiều sau giờ chốt (ATT-05b `noticeOnly`): chỉ báo cô, không đổi điểm danh/suất.
  final bool afternoonNoticeSent;
  final int unreadNotifications;

  /// Chỉ thực đơn đã công bố mới có (NUT-08).
  final bool menuPublished;

  /// Tên hoạt động chính trong ngày; null khi chưa có (OBS-07 OPEN).
  final String? activityTitle;
}

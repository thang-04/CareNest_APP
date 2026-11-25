import 'package:flutter/foundation.dart';

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
enum AttendanceStatus { present, excused, unexcused, notRecorded }

/// Bữa trong ngày — khớp enum BE `MealSession`.
enum MealSession {
  morning('MORNING', 'Sáng'),
  lunch('LUNCH', 'Trưa'),
  afternoon('AFTERNOON', 'Chiều');

  const MealSession(this.code, this.label);
  final String code;
  final String label;
}

/// Một dòng nhập: Có mặt / Vắng + ăn từng bữa (UC50). Dạng như BE `SaveAttendanceRequest.Entry`
/// `{childId, status, meals: Map<MealSession, Boolean>}`.
@immutable
class KidAttendance {
  const KidAttendance({
    required this.childId,
    required this.fullName,
    required this.status,
    this.meals = const {},
    this.note,
    this.hasLeaveNotice = false,
  });

  final String childId;
  final String fullName;
  final AttendanceStatus status;

  /// Bữa bé ăn tại trường; chỉ có nghĩa khi Có mặt. BE hiện tự tính theo điểm danh (ATT-02).
  final Map<MealSession, bool> meals;

  /// Trạng thái nhập trên APP: trẻ có mặt và được chọn tham gia ít nhất một bữa.
  bool get eatsAtSchool =>
      status == AttendanceStatus.present && meals.values.any((eats) => eats);

  /// Ghi chú BE trả dưới tên: đơn nghỉ, dị ứng, suất ăn riêng.
  final String? note;

  /// Có đơn nghỉ hôm nay ⇒ BE đặt sẵn có phép (ATT-04); GV không tự chọn có phép (ATT-09).
  final bool hasLeaveNotice;

  KidAttendance copyWith({
    AttendanceStatus? status,
    Map<MealSession, bool>? meals,
  }) {
    return KidAttendance(
      childId: childId,
      fullName: fullName,
      status: status ?? this.status,
      meals: meals ?? this.meals,
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
    this.mealSessions = MealSession.values,
    this.lockAt,
    this.canRecord = true,
    this.locked = false,
    this.schoolDay = true,
  });

  final ClassSummary classSummary;
  final DateTime date;
  final List<KidAttendance> kids;

  /// Các bữa nhóm tuổi của lớp được ăn — BE `ClassAttendanceResponse.mealSessions`.
  final List<MealSession> mealSessions;

  /// Giờ khoá nhập BE trả (cut-off P-03 PENDING); APP chỉ hiển thị, không tự khoá theo giờ máy.
  final String? lockAt;

  /// BE `ClassAttendanceResponse.canRecord` (quyền ATTENDANCE_RECORD, lớp được phân công).
  final bool canRecord;

  /// BE `DayInfoResponse.locked` — quá giờ khóa và chưa được PHT mở lại (ATT-06, ATT-08).
  final bool locked;

  /// BE `DayInfoResponse.schoolDay`.
  final bool schoolDay;

  /// Như Web: chỉ sửa khi có quyền, là ngày học và chưa khóa.
  bool get editable => canRecord && schoolDay && !locked;
}

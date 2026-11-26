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
  afternoon('AFTERNOON', 'Xế');

  const MealSession(this.code, this.label);
  final String code;
  final String label;
}

/// Buổi trong đơn nghỉ / bản ghi — khớp enum BE `LeavePart`.
enum DayPartCode {
  fullDay('FULL_DAY', 'Cả ngày'),
  morning('MORNING', 'Buổi sáng'),
  afternoon('AFTERNOON', 'Buổi chiều');

  const DayPartCode(this.code, this.label);
  final String code;
  final String label;

  static DayPartCode? fromCode(Object? code) =>
      DayPartCode.values.where((part) => part.code == code).firstOrNull;
}

/// Đơn nghỉ phụ huynh còn hiệu lực hôm đó — BE `LeaveRequestDtos.LeaveTag`; chỉ để xem.
@immutable
class LeaveNotice {
  const LeaveNotice({
    required this.fromDate,
    required this.toDate,
    this.reason = '',
    this.part = DayPartCode.fullDay,
    this.eats,
    this.eatsMeals = const [],
    this.noticeOnly = false,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final DayPartCode part;

  /// null = đơn không hỏi "trẻ tham gia ăn" (cả ngày hoặc buổi còn học không có bữa).
  final bool? eats;
  final List<MealSession> eatsMeals;

  /// Báo nghỉ chiều sau giờ chốt: chỉ thông báo cho lớp, không đổi điểm danh.
  final bool noticeOnly;

  bool get isHalfDay => !noticeOnly && part != DayPartCode.fullDay;
}

/// Tóm tắt sức khỏe trong ngày của trẻ trên sổ điểm danh — BE `HealthSummary` (chỉ hiển thị).
@immutable
class KidHealthBrief {
  const KidHealthBrief({
    this.checked = false,
    this.noted = false,
    this.temperature,
  });

  final bool checked;

  /// Lần ghi mới nhất GV chọn "Có dấu hiệu".
  final bool noted;
  final double? temperature;
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
    this.code,
    this.hasAllergy = false,
    this.mealRegistered = true,
    this.leave,
    this.absentPart,
    this.absentPartUnexcused = false,
    this.health = const KidHealthBrief(),
  });

  final String childId;
  final String fullName;
  final AttendanceStatus status;

  /// Bữa trẻ ăn tại trường; chỉ có nghĩa khi Có mặt.
  final Map<MealSession, bool> meals;

  /// Mã trẻ nếu BE trả (sổ lớp hiện chưa có field này).
  final String? code;

  /// Hồ sơ có khai báo dị ứng — BE `ChildBrief.hasAllergy`.
  final bool hasAllergy;

  /// BE `ChildBrief.mealRegistered`: false = trẻ không báo ăn.
  final bool mealRegistered;
  final LeaveNotice? leave;

  /// Buổi nghỉ theo đơn nửa buổi (BE `RecordView.absentPart`), chỉ morning/afternoon.
  final DayPartCode? absentPart;
  final bool absentPartUnexcused;
  final KidHealthBrief health;

  bool get hasLeaveNotice => leave != null;

  /// Trạng thái nhập trên APP: trẻ có mặt và được chọn tham gia ít nhất một bữa.
  bool get eatsAtSchool =>
      status == AttendanceStatus.present && meals.values.any((eats) => eats);

  bool get isAbsent =>
      status == AttendanceStatus.excused ||
      status == AttendanceStatus.unexcused;

  /// Buổi có mặt BE ghi (đã trừ buổi nghỉ theo đơn); chỉ hiển thị.
  DayPartCode? get presentPart {
    if (status != AttendanceStatus.present) return null;
    return switch (absentPart) {
      DayPartCode.morning => DayPartCode.afternoon,
      DayPartCode.afternoon => DayPartCode.morning,
      _ => DayPartCode.fullDay,
    };
  }

  KidAttendance copyWith({
    AttendanceStatus? status,
    Map<MealSession, bool>? meals,
  }) {
    return KidAttendance(
      childId: childId,
      fullName: fullName,
      status: status ?? this.status,
      meals: meals ?? this.meals,
      code: code,
      hasAllergy: hasAllergy,
      mealRegistered: mealRegistered,
      leave: leave,
      absentPart: absentPart,
      absentPartUnexcused: absentPartUnexcused,
      health: health,
    );
  }

  /// Khác bản đã lưu ở trạng thái hoặc bữa ăn ⇒ cần gửi lại.
  bool changedFrom(KidAttendance saved) {
    if (status == AttendanceStatus.notRecorded) return false;
    if (status != saved.status) return true;
    return !mapEquals(_trueMeals(meals), _trueMeals(saved.meals));
  }

  static Map<MealSession, bool> _trueMeals(Map<MealSession, bool> meals) => {
    for (final entry in meals.entries)
      if (entry.value) entry.key: true,
  };
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
    this.today,
  });

  final ClassSummary classSummary;
  final DateTime date;
  final List<KidAttendance> kids;

  /// Các bữa nhóm tuổi của lớp được ăn — BE `ClassAttendanceResponse.mealSessions`.
  final List<MealSession> mealSessions;

  /// Giờ khoá nhập BE trả (cut-off); APP chỉ hiển thị, không tự khoá theo giờ máy.
  final String? lockAt;

  /// BE `ClassAttendanceResponse.canRecord` (quyền ATTENDANCE_RECORD, lớp được phân công).
  final bool canRecord;

  /// BE `DayInfoResponse.locked` — quá giờ khóa và chưa được PHT mở lại (ATT-06, ATT-08).
  final bool locked;

  /// BE `DayInfoResponse.schoolDay`.
  final bool schoolDay;

  /// BE `DayInfoResponse.today` (ngày hôm nay theo giờ trường).
  final DateTime? today;

  /// Như Web: chỉ sửa khi có quyền, là ngày học và chưa khóa.
  bool get editable => canRecord && schoolDay && !locked;
}

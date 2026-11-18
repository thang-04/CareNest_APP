import 'package:flutter/foundation.dart';

/// Mọi nhãn/đánh giá dưới đây là giá trị BE trả (đã công bố cho phụ huynh — PAR-02, P-13b);
/// APP không tự xếp loại, không tự tính.

/// Tiêu chí đánh giá hằng ngày; danh sách thật do trường cấu hình (OBS-02, P-11).
enum ReviewCriterion { health, emotion, learning, behavior }

@immutable
class ReviewTag {
  const ReviewTag({required this.criterion, required this.label});

  final ReviewCriterion criterion;

  /// "Sức khỏe: Tốt"
  final String label;
}

@immutable
class DailyReview {
  const DailyReview({required this.teacher, required this.tags, this.note});

  /// "Cô Trần Thu Hà"
  final String teacher;
  final List<ReviewTag> tags;
  final String? note;
}

@immutable
class ActivityEntry {
  const ActivityEntry({
    required this.time,
    required this.title,
    this.detail,
    this.isCurrent = false,
  });

  final DateTime time;
  final String title;
  final String? detail;
  final bool isCurrent;
}

@immutable
class ActivityDay {
  const ActivityDay({
    required this.date,
    required this.entries,
    this.review,
    this.photoTitle,
    this.photoCount = 0,
  });

  final DateTime date;
  final List<ActivityEntry> entries;
  final DailyReview? review;
  final String? photoTitle;
  final int photoCount;
}

enum AttendanceDayStatus { present, excused, absent }

@immutable
class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.status,
    this.arrivedAt,
    this.mealsLine,
    this.pickupLine,
    this.mealCancelled = false,
  });

  final DateTime date;
  final AttendanceDayStatus status;
  final DateTime? arrivedAt;

  /// "đã ăn sáng · trưa · chiều" — không dùng ký tự ✓ vì font Be Vietnam Pro không có
  final String? mealsLine;

  /// "16:45 · Mẹ"
  final String? pickupLine;
  final bool mealCancelled;
}

/// Một tháng điểm danh; các số đếm là BE trả, không đếm từ danh sách ngày trên máy.
@immutable
class AttendanceMonth {
  const AttendanceMonth({
    required this.month,
    required this.presentCount,
    required this.excusedCount,
    required this.absentCount,
    required this.cancelledMealCount,
    required this.days,
  });

  final DateTime month;
  final int presentCount;
  final int excusedCount;
  final int absentCount;
  final int cancelledMealCount;
  final List<AttendanceDay> days;
}

@immutable
class Guardian {
  const Guardian({
    required this.relation,
    required this.name,
    required this.phone,
  });

  final String relation;
  final String name;
  final String phone;
}

/// Trạng thái một mục khai báo sức khỏe khi tiếp nhận: BE `REPORTED` / `NONE_REPORTED` /
/// `NOT_PROVIDED` (CHD-06).
enum DeclarationState { reported, noneReported, notProvided }

/// Mục khai báo có chữ đi kèm khi `reported`: chế độ ăn, tên bệnh tiền sử (HLT-06).
@immutable
class DeclaredItem {
  const DeclaredItem.reported(String this.text)
    : state = DeclarationState.reported;
  const DeclaredItem.noneReported()
    : state = DeclarationState.noneReported,
      text = null;
  const DeclaredItem.notProvided()
    : state = DeclarationState.notProvided,
      text = null;

  final DeclarationState state;
  final String? text;
}

/// Khai báo sức khỏe khi tiếp nhận (CHD-06): dị ứng, chế độ ăn, tiền sử bản thân và gia đình.
@immutable
class DeclaredHealth {
  const DeclaredHealth({
    required this.allergyState,
    this.allergies = const [],
    required this.diet,
    required this.selfHistory,
    required this.familyHistory,
  });

  final DeclarationState allergyState;

  /// Tên chất gây dị ứng khi [allergyState] là `reported` (HLT-06).
  final List<String> allergies;
  final DeclaredItem diet;
  final DeclaredItem selfHistory;
  final DeclaredItem familyHistory;
}

/// Hồ sơ của bé cho phụ huynh (tab Bé của tôi): chỉ xem, nhà trường sửa (CHD-05).
@immutable
class ChildProfile {
  const ChildProfile({
    required this.fullName,
    required this.className,
    required this.ageLabel,
    required this.schoolYear,
    required this.birthDate,
    required this.gender,
    required this.campus,
    required this.teachers,
    required this.health,
    required this.guardians,
  });

  final String fullName;

  /// "Mầm 3A"
  final String className;

  /// "4 tuổi"
  final String ageLabel;

  /// "2026–2027"
  final String schoolYear;

  /// "14/03/2022 (4 tuổi)"
  final String birthDate;
  final String gender;
  final String campus;

  /// "Cô Trần Thu Hà · Cô Lê Mai"
  final String teachers;
  final DeclaredHealth health;
  final List<Guardian> guardians;
}

abstract interface class MyChildSource {
  Future<ActivityDay> loadActivities(String childId);
  Future<AttendanceMonth> loadAttendance(String childId);
  Future<ChildProfile> loadProfile(String childId);
}

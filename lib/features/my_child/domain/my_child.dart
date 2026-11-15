import 'package:flutter/foundation.dart';

/// Mọi nhãn/đánh giá dưới đây là giá trị BE trả (đã công bố cho phụ huynh — PAR-02, P-13b);
/// APP không tự xếp loại, không tự tính.

enum DayEventKind { attendance, meal, activity, pickup }

@immutable
class DayEvent {
  const DayEvent({required this.time, required this.kind, required this.label});

  final DateTime time;
  final DayEventKind kind;

  /// "Điểm danh – Có mặt"
  final String label;
}

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
class LeaveSummary {
  const LeaveSummary({
    required this.title,
    required this.detail,
    required this.seenByTeacher,
  });

  final String title;
  final String detail;
  final bool seenByTeacher;
}

@immutable
class ChildToday {
  const ChildToday({
    required this.date,
    required this.events,
    this.review,
    this.upcomingLeave,
  });

  final DateTime date;
  final List<DayEvent> events;
  final DailyReview? review;
  final LeaveSummary? upcomingLeave;
}

@immutable
class WeightPoint {
  const WeightPoint(this.monthLabel, this.kg);

  /// "T10"
  final String monthLabel;
  final double kg;
}

@immutable
class HealthSummary {
  const HealthSummary({
    required this.measuredOn,
    required this.height,
    required this.weight,
    required this.weightTrend,
    required this.dietLine,
    this.nutritionLabel,
  });

  final DateTime measuredOn;

  /// "104 cm", "17,2 kg" — chuỗi BE định dạng sẵn.
  final String height;
  final String weight;
  final List<WeightPoint> weightTrend;

  /// "Không có dị ứng · ăn suất thường"
  final String dietLine;

  /// Nhãn BE trả khi có ngưỡng đã chốt (HLT-03 / P-13 PENDING); null ⇒ không hiện dòng này.
  final String? nutritionLabel;
}

@immutable
class DevelopmentSummary {
  const DevelopmentSummary({
    required this.weekRange,
    required this.weekNote,
    required this.weekAuthor,
    required this.weekConfirmed,
    required this.monthlyTitle,
    required this.flagMonth,
    required this.flagsEarned,
    required this.flagsNeeded,
    required this.flagSlots,
    required this.yearEndNote,
  });

  /// "05/10 – 09/10"
  final String weekRange;
  final String weekNote;

  /// "Cô Trần Thu Hà · 09/10/2026"
  final String weekAuthor;
  final bool weekConfirmed;
  final String monthlyTitle;

  /// Phiếu bé ngoan (OBS-10 PROPOSED): số phiếu và ngưỡng do BE trả.
  final String flagMonth;
  final int flagsEarned;
  final int flagsNeeded;
  final int flagSlots;
  final String yearEndNote;
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

@immutable
class ChildProfile {
  const ChildProfile({
    required this.fullName,
    required this.classLine,
    required this.birthDate,
    required this.gender,
    required this.campus,
    required this.teachers,
    required this.healthLine,
    required this.guardians,
  });

  final String fullName;

  /// "Lớp Mầm 3A · Năm học 2026–2027"
  final String classLine;

  /// "14/03/2022 (4 tuổi)"
  final String birthDate;
  final String gender;
  final String campus;
  final String teachers;
  final String healthLine;
  final List<Guardian> guardians;
}

abstract interface class MyChildSource {
  Future<ChildToday> loadToday(String childId);
  Future<HealthSummary> loadHealth(String childId);
  Future<DevelopmentSummary> loadDevelopment(String childId);
  Future<ActivityDay> loadActivities(String childId);
  Future<AttendanceMonth> loadAttendance(String childId);
  Future<ChildProfile> loadProfile(String childId);
}

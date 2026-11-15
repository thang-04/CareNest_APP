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

/// Mức đánh giá ngày (OBS-02): Đạt / Cần cố gắng / Chưa đạt.
enum ReviewLevel { achieved, needsEffort, notAchieved }

@immutable
class ReviewTag {
  const ReviewTag({required this.level, required this.label});

  final ReviewLevel level;

  /// "Sức khỏe: Đạt"
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
  const LeaveSummary({required this.title, required this.detail});

  final String title;

  /// "Vắng có phép 13/10" (ATT-04)
  final String detail;
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

/// Nhận xét định kỳ theo tháng, học kỳ, cuối năm — không có kỳ tuần (OBS-06).
@immutable
class DevelopmentSummary {
  const DevelopmentSummary({
    required this.commentTitle,
    required this.commentNote,
    required this.commentAuthor,
    required this.commentConfirmed,
    required this.previousCommentTitle,
    required this.flagMonth,
    required this.flagsEarned,
    required this.flagsNeeded,
    required this.flagSlots,
    required this.yearEndNote,
  });

  /// "Nhận xét tháng 9/2026"
  final String commentTitle;
  final String commentNote;

  /// "Cô Trần Thu Hà · 30/09/2026"
  final String commentAuthor;
  final bool commentConfirmed;

  /// Kỳ nhận xét trước, vd. "Nhận xét tháng 8/2026"
  final String previousCommentTitle;

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
    this.pickupLine,
  });

  final DateTime date;

  /// Có mặt là ăn đủ các bữa đã cấu hình, không ghi từng bữa (ATT-02).
  final AttendanceDayStatus status;
  final DateTime? arrivedAt;

  /// "16:45 · Mẹ"
  final String? pickupLine;
}

/// Một tháng điểm danh; các số đếm là BE trả, không đếm từ danh sách ngày trên máy.
@immutable
class AttendanceMonth {
  const AttendanceMonth({
    required this.month,
    required this.presentCount,
    required this.excusedCount,
    required this.absentCount,
    required this.days,
  });

  final DateTime month;
  final int presentCount;
  final int excusedCount;
  final int absentCount;
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

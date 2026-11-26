import 'package:flutter/foundation.dart';

import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';

/// Một ngày học trong tổng hợp — BE `AttendanceSummaryResponse.DayRow`; số liệu do BE tính.
@immutable
class AttendanceSummaryDay {
  const AttendanceSummaryDay({
    required this.date,
    this.present = 0,
    this.excused = 0,
    this.unexcused = 0,
    this.missing = 0,
    this.mealTotal = 0,
    this.meals = const {},
    this.morningOff = 0,
    this.afternoonOff = 0,
  });

  final DateTime date;
  final int present;
  final int excused;
  final int unexcused;
  final int missing;

  /// Số trẻ có ăn ít nhất một bữa.
  final int mealTotal;
  final Map<MealSession, int> meals;
  final int morningOff;
  final int afternoonOff;
}

/// Một trẻ trong khoảng — BE `AttendanceSummaryResponse.ChildTotal`.
@immutable
class AttendanceSummaryChild {
  const AttendanceSummaryChild({
    required this.childId,
    required this.fullName,
    this.attendedDays = 0,
    this.excused = 0,
    this.unexcused = 0,
    this.mealDays = 0,
    this.mealCounts = const {},
    this.morningOff = 0,
    this.afternoonOff = 0,
  });

  final String childId;
  final String fullName;

  /// Ngày có mặt quy đổi (nghỉ nửa buổi tính 0,5) do BE tính.
  final double attendedDays;
  final int excused;
  final int unexcused;

  /// Số ngày trẻ ăn ít nhất một bữa.
  final int mealDays;
  final Map<MealSession, int> mealCounts;
  final int morningOff;
  final int afternoonOff;
}

/// Tổng hợp điểm danh một lớp trong khoảng ngày — BE `AttendanceSummaryResponse.ClassSummary`.
@immutable
class AttendanceSummary {
  const AttendanceSummary({
    required this.className,
    required this.from,
    required this.to,
    required this.size,
    required this.mealSessions,
    required this.days,
    required this.children,
  });

  final String className;
  final DateTime from;
  final DateTime to;
  final int size;
  final List<MealSession> mealSessions;
  final List<AttendanceSummaryDay> days;
  final List<AttendanceSummaryChild> children;
}

abstract interface class AttendanceSummarySource {
  /// BE: `GET /classes/{classId}/attendance/summary[?from=&to=]`; thiếu from/to ⇒ BE chọn khoảng mặc định.
  Future<AttendanceSummary> load(
    String classId, {
    DateTime? from,
    DateTime? to,
  });
}

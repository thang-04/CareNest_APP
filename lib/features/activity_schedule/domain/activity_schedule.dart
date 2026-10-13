import 'package:flutter/foundation.dart';

/// Lịch hoạt động lớp — ngữ cảnh cho đánh giá, nguồn còn OPEN (OBS-07, ADR-0006).
/// CareNest không soạn/duyệt giáo án (OBS-08) ⇒ không có trạng thái duyệt.
@immutable
class ScheduleEntry {
  const ScheduleEntry({
    required this.time,
    required this.title,
    this.detail,
    this.isCurrent = false,
  });

  /// "08:00"
  final String time;
  final String title;
  final String? detail;
  final bool isCurrent;
}

@immutable
class WeekSchedule {
  const WeekSchedule({
    required this.weekStart,
    required this.theme,
    required this.days,
  });

  final DateTime weekStart;

  /// "Mùa thu của bé"
  final String theme;

  /// Thứ trong tuần (DateTime.monday…) → hoạt động trong ngày.
  final Map<int, List<ScheduleEntry>> days;
}

abstract interface class ActivityScheduleSource {
  Future<WeekSchedule> loadWeek(String classId);
}

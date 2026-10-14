import 'package:flutter/foundation.dart';

/// Loại việc trên Trang chủ Giáo viên ⇒ chọn icon và màn mở ra.
enum TeacherTaskKind { attendance, leave, review, pickup, health, mealPhotos }

/// Mức nhấn của badge việc: cần làm ngay / có mới / thông tin.
enum TaskBadgeLevel { todo, fresh, info }

@immutable
class TeacherTask {
  const TeacherTask({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeLevel,
    this.highlighted = false,
  });

  final TeacherTaskKind kind;
  final String title;
  final String subtitle;
  final String badge;
  final TaskBadgeLevel badgeLevel;
  final bool highlighted;
}

/// Việc hôm nay của giáo viên với lớp được phân công (AUTH-03) — mockup T01. Số đếm, hạn giờ do BE trả.
@immutable
class TeacherToday {
  const TeacherToday({
    required this.teacherName,
    required this.date,
    required this.className,
    required this.childCount,
    required this.tasks,
    this.currentActivity,
    this.deadlineNote,
    this.attendanceRecorded,
  });

  /// "Trần Thu Hà"
  final String teacherName;
  final DateTime date;
  final String className;
  final int childCount;

  /// "08:00 Tạo hình" — nguồn lịch hoạt động còn OPEN (OBS-07).
  final String? currentActivity;

  /// "Hạn điểm danh: 08:30 · còn 47 phút" — cut-off P-03, BE trả.
  final String? deadlineNote;

  /// Số bé đã điểm danh hôm nay — BE trả, APP không đếm; null ⇒ không vẽ vòng tiến độ.
  /// Field chưa có trong contract BE (đề xuất khi viết endpoint trang chủ GV).
  final int? attendanceRecorded;
  final List<TeacherTask> tasks;
}

abstract interface class TeacherHomeSource {
  Future<TeacherToday> loadToday();
}

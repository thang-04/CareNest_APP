import 'package:flutter/foundation.dart';

/// Loại việc trên Trang chủ Phó HT ⇒ chọn icon và màn mở ra.
enum CampusTaskKind { confirmMeals, approvals, kitchen, menu, children }

/// Mức nhấn của badge việc: cần làm / có mới / đang theo dõi / đã xong / chỉ xem.
enum CampusBadgeLevel { todo, fresh, watch, done, view }

@immutable
class CampusTask {
  const CampusTask({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.level,
    this.highlighted = false,
  });

  final CampusTaskKind kind;
  final String title;
  final String subtitle;
  final String badge;
  final CampusBadgeLevel level;
  final bool highlighted;
}

/// Mốc buổi sáng của cơ sở theo giờ cấu hình (khoá điểm danh → tổng hợp → chốt suất → bếp nhận số → bữa trưa).
enum MorningStepKind {
  attendanceLock,
  mealSummary,
  mealConfirm,
  kitchenReceive,
  lunch,
}

enum MorningStepState { done, current, upcoming }

/// Một mốc buổi sáng BE trả (PROPOSED, chưa có trong contract): giờ, tên, ghi chú và trạng thái.
/// APP không tự suy trạng thái từ đồng hồ máy.
@immutable
class MorningStep {
  const MorningStep({
    required this.kind,
    required this.time,
    required this.title,
    required this.state,
    this.note,
  });

  final MorningStepKind kind;
  final DateTime time;
  final String title;
  final MorningStepState state;

  /// "6/6 lớp đã điểm danh"
  final String? note;
}

enum CampusPendingKind { mealAdjustment, rewards }

/// Một mục chờ Phó HT duyệt hiện ở Trang chủ (PROPOSED): điều chỉnh suất mở thẳng màn duyệt theo `id`.
@immutable
class CampusPendingItem {
  const CampusPendingItem({
    required this.kind,
    required this.title,
    required this.note,
    this.id,
  });

  final CampusPendingKind kind;

  /// ID điều chỉnh suất; null với đề xuất khen thưởng (mở cả danh sách).
  final String? id;

  /// "Điều chỉnh suất · Mầm 3A"
  final String title;

  /// "+1 suất · 09:05"
  final String note;
}

/// Hôm nay của cơ sở Phó HT phụ trách (AUTH-02) — mockup V01. Mọi số do BE tổng hợp trong scope (AUTH-08).
@immutable
class CampusToday {
  const CampusToday({
    required this.staffName,
    required this.campusName,
    required this.date,
    required this.classCount,
    required this.enrolled,
    required this.present,
    required this.excused,
    required this.absent,
    required this.pendingApprovals,
    required this.tasks,
    this.morning = const [],
    this.pending = const [],
  });

  /// "Lê Văn Bình"
  final String staffName;

  /// "Cơ sở chính – Thượng Hồng"
  final String campusName;
  final DateTime date;
  final int classCount;
  final int enrolled;
  final int present;
  final int excused;
  final int absent;
  final int pendingApprovals;
  final List<CampusTask> tasks;

  /// Rỗng ⇒ BE chưa trả mốc (vd. ngày không học), màn ẩn thẻ mốc.
  final List<MorningStep> morning;

  /// Mục chờ Phó HT duyệt, mới nhất trước.
  final List<CampusPendingItem> pending;
}

/// Bếp của cơ sở cho màn trạng thái bếp (V05): bếp nào, phiếu xuất kho, báo thiếu gần nhất.
@immutable
class CampusKitchen {
  const CampusKitchen({
    required this.kitchenLabel,
    required this.slipNote,
    this.shortageTitle,
    this.shortageNote,
  });

  /// "Bếp cơ sở chính · Cô Nguyễn Thị Mai"
  final String kitchenLabel;

  /// "Phiếu xuất kho PXK-1012 · đã duyệt 08:50"
  final String slipNote;

  /// "Báo thiếu từ bếp · 07:55"
  final String? shortageTitle;
  final String? shortageNote;
}

abstract interface class CampusTodaySource {
  Future<CampusToday> loadToday();
  Future<CampusKitchen> loadKitchen();
}

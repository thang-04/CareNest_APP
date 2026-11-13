import 'package:flutter/foundation.dart';

/// Loại mục trên Trang chủ Phó HT ⇒ chọn icon và màn (chỉ xem) mở ra.
enum CampusTaskKind { mealCount, approvals, menu, children }

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

/// Việc chờ PHT xử lý trên Web: số suất chưa xác nhận (NUT-02), đề xuất khen thưởng chờ xét (OBS-14).
enum CampusPendingKind { mealCount, rewards }

/// Một việc chờ xử lý hiện ở Trang chủ (PROPOSED). Trên App chỉ mở màn xem (AUTH-21, BE ADR-0026).
@immutable
class CampusPendingItem {
  const CampusPendingItem({
    required this.kind,
    required this.title,
    required this.note,
  });

  final CampusPendingKind kind;

  /// "Số suất chưa xác nhận"
  final String title;

  /// "182 suất · hạn 08:30"
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
    required this.pendingCount,
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
  final int pendingCount;
  final List<CampusTask> tasks;

  /// Rỗng ⇒ BE chưa trả mốc (vd. ngày không học), màn ẩn thẻ mốc.
  final List<MorningStep> morning;

  /// Việc chờ PHT xử lý trên Web.
  final List<CampusPendingItem> pending;
}

abstract interface class CampusTodaySource {
  Future<CampusToday> loadToday();
}

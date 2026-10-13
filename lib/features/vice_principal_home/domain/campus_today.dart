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

/// Hôm nay của cơ sở Phó HT phụ trách (AUTH-02) — mockup V01. Mọi số do BE tổng hợp trong scope (AUTH-08).
@immutable
class CampusToday {
  const CampusToday({
    required this.staffName,
    required this.campusName,
    required this.classCount,
    required this.enrolled,
    required this.present,
    required this.excused,
    required this.absent,
    required this.pendingApprovals,
    required this.tasks,
  });

  /// "Lê Văn Bình"
  final String staffName;

  /// "Cơ sở chính – Thượng Hồng"
  final String campusName;
  final int classCount;
  final int enrolled;
  final int present;
  final int excused;
  final int absent;
  final int pendingApprovals;
  final List<CampusTask> tasks;
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

import 'package:flutter/foundation.dart';

/// Kết quả xử lý yêu cầu — BE ghi nhận, APP chỉ gửi quyết định.
enum RequestDecision { pending, approved, rejected }

/// Trẻ liên quan tới yêu cầu điều chỉnh suất (Phó HT xem được tên trong cơ sở phụ trách, AUTH-02).
@immutable
class AdjustmentChild {
  const AdjustmentChild({required this.fullName, required this.note});

  final String fullName;

  /// "Đến lớp 08:52 · suất thường · không dị ứng"
  final String note;
}

/// Yêu cầu điều chỉnh số suất sau giờ chốt (NUT-03; cách xử lý thay đổi muộn P-04 PENDING).
/// Mọi số "sau khi duyệt" và tình trạng bếp do BE tính; APP không cộng trừ.
@immutable
class MealAdjustment {
  const MealAdjustment({
    required this.id,
    required this.className,
    required this.fromCount,
    required this.toCount,
    required this.deltaLabel,
    required this.senderName,
    required this.sentAt,
    required this.reason,
    required this.summary,
    required this.cutoffLabel,
    required this.statusLabel,
    required this.childrenTitle,
    required this.children,
    required this.kitchenTitle,
    required this.kitchenNote,
    required this.kitchenBadge,
    required this.totalNow,
    required this.totalAfter,
    required this.splitAfter,
    this.decision = RequestDecision.pending,
  });

  final String id;
  final String className;
  final int fromCount;
  final int toCount;

  /// "+1 suất"
  final String deltaLabel;
  final String senderName;
  final DateTime sentAt;
  final String reason;

  /// Dòng tóm tắt trong danh sách: "GV sửa điểm danh 09:05"
  final String summary;

  /// "sau giờ chốt 08:30"
  final String cutoffLabel;

  /// Nhãn trạng thái BE trả: "Chờ Phó HT"
  final String statusLabel;

  /// "Bé được thêm suất"
  final String childrenTitle;
  final List<AdjustmentChild> children;

  /// "Bữa trưa: Đang nấu"
  final String kitchenTitle;

  /// "Bắt đầu 09:10 · còn kịp chia thêm 1 suất"
  final String kitchenNote;

  /// "Kịp"
  final String kitchenBadge;
  final int totalNow;
  final int totalAfter;

  /// "176 / 7" — thường / thay thế sau khi duyệt.
  final String splitAfter;
  final RequestDecision decision;

  MealAdjustment decided(RequestDecision value) => MealAdjustment(
    id: id,
    className: className,
    fromCount: fromCount,
    toCount: toCount,
    deltaLabel: deltaLabel,
    senderName: senderName,
    sentAt: sentAt,
    reason: reason,
    summary: summary,
    cutoffLabel: cutoffLabel,
    statusLabel: statusLabel,
    childrenTitle: childrenTitle,
    children: children,
    kitchenTitle: kitchenTitle,
    kitchenNote: kitchenNote,
    kitchenBadge: kitchenBadge,
    totalNow: totalNow,
    totalAfter: totalAfter,
    splitAfter: splitAfter,
    decision: value,
  );
}

abstract interface class MealAdjustmentSource {
  /// Yêu cầu còn chờ Phó HT duyệt trong cơ sở phụ trách.
  Future<List<MealAdjustment>> loadPending();
  Future<MealAdjustment?> loadOne(String id);

  /// Từ chối phải có lý do; BE kiểm tra lại và trả lý do về người gửi.
  Future<void> decide(String id, {required bool approve, String? reason});
}

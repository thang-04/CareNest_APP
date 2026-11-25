import 'package:flutter/foundation.dart';

/// Trạng thái danh sách khen thưởng của LỚP — khớp BE `RewardStatus`; nhãn như Web
/// (`REWARD_STATUS_LABELS`). Null ở BE = lớp chưa lập danh sách.
enum RewardStatus {
  draft('DRAFT', 'Đang lập'),
  pendingVp('PENDING_VP', 'Chờ PHT xem xét'),
  pendingPrincipal('PENDING_PRINCIPAL', 'Chờ HT phê duyệt'),
  approved('APPROVED', 'Đã phê duyệt'),
  returned('RETURNED', 'Bị trả lại');

  const RewardStatus(this.code, this.label);
  final String code;
  final String label;
}

/// Một trẻ — tập con BE `RewardChildRow`. Danh hiệu là chuỗi BE trả (`titleOptions`), APP không tự đặt.
@immutable
class TeacherRewardChild {
  const TeacherRewardChild({
    required this.childId,
    required this.fullName,
    required this.schoolDays,
    required this.presentDays,
    required this.weeklyTickets,
    required this.monthlyTickets,
    this.suggested = const [],
    this.titles = const [],
    this.note = '',
  });

  final String childId;
  final String fullName;

  /// Ngày học của lớp và ngày có mặt cả năm (BE tính).
  final int schoolDays;
  final int presentDays;
  final int weeklyTickets;
  final int monthlyTickets;

  /// Danh hiệu hệ thống gợi ý (OBS-14) — hiện kèm chữ "gợi ý".
  final List<String> suggested;

  /// Danh hiệu GV đã chọn trên Web.
  final List<String> titles;
  final String note;
}

/// BE `RewardClassDetail` (`GET /assessment/reward-lists/classes/{classId}`); App chỉ xem.
@immutable
class TeacherRewards {
  const TeacherRewards({
    required this.className,
    required this.schoolYearLabel,
    required this.children,
    this.status,
    this.titleOptions = const [],
  });

  final String className;
  final String schoolYearLabel;

  /// Null ⇒ lớp chưa lập danh sách.
  final RewardStatus? status;
  final List<String> titleOptions;
  final List<TeacherRewardChild> children;
}

abstract interface class TeacherRewardSource {
  Future<TeacherRewards> load(String classId);
}

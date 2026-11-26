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

/// Loại phiếu bé ngoan trên Web: "Bé ngoan" (tuần) và "Bé ngoan toàn diện" (tháng) — BE `TicketType`.
enum TicketKind {
  weekly('WEEKLY'),
  monthly('MONTHLY');

  const TicketKind(this.code);
  final String code;
}

/// Một kỳ phiếu đã kết thúc (BE `TicketPeriod`); [weekNo] chỉ có ở phiếu tuần.
@immutable
class TicketPeriod {
  const TicketPeriod({required this.start, required this.end, this.weekNo});

  final DateTime start;
  final DateTime end;
  final int? weekNo;
}

/// Một trẻ trong bảng phiếu (BE `TicketBoardRow`); App chỉ xem, không phát phiếu.
@immutable
class TicketBoardRow {
  const TicketBoardRow({
    required this.childId,
    required this.fullName,
    required this.presentDays,
    required this.flagCount,
    required this.weeklyTickets,
    required this.eligible,
    this.issuedAt,
    this.hasTicket = false,
    this.issuedElsewhere = false,
    this.canIssue = true,
  });

  final String childId;
  final String fullName;

  /// Phiếu tuần: ngày có mặt và số cờ; phiếu tháng: số phiếu tuần (BE tính).
  final int presentDays;
  final int flagCount;
  final int weeklyTickets;

  /// BE xét đủ điều kiện.
  final bool eligible;
  final bool hasTicket;
  final DateTime? issuedAt;
  final bool issuedElsewhere;

  /// BE: false = chỉ xem lịch sử (trẻ không thuộc lớp cuối kỳ).
  final bool canIssue;
}

@immutable
class TicketBoard {
  const TicketBoard({
    required this.className,
    required this.kind,
    required this.periods,
    required this.rows,
    this.period,
    this.rules = const {},
  });

  final String className;
  final TicketKind kind;

  /// Các kỳ đã kết thúc, mới nhất trước.
  final List<TicketPeriod> periods;

  /// Null = chưa có kỳ nào kết thúc.
  final TicketPeriod? period;
  final List<TicketBoardRow> rows;

  /// Ngưỡng BE trả (`WEEK_MIN_FLAGS`, `MONTH_MIN_WEEKLY_TICKETS`) — chỉ để hiện "cần N".
  final Map<String, int> rules;
}

@immutable
class TicketSummaryRow {
  const TicketSummaryRow({
    required this.childId,
    required this.fullName,
    required this.weekly,
    required this.monthly,
    required this.flags,
  });

  final String childId;
  final String fullName;
  final int weekly;
  final int monthly;
  final int flags;
}

/// Tổng hợp phiếu theo trẻ (BE `TicketSummaryResponse`); [month] null = cả năm học.
@immutable
class TicketSummary {
  const TicketSummary({
    required this.className,
    required this.months,
    required this.rows,
    this.month,
    this.weekly = 0,
    this.monthly = 0,
    this.children = 0,
    this.total = 0,
  });

  final String className;
  final DateTime? month;
  final List<DateTime> months;
  final List<TicketSummaryRow> rows;
  final int weekly;
  final int monthly;

  /// Trẻ có phiếu / tổng số trẻ.
  final int children;
  final int total;
}

/// Một lớp trong danh sách đề xuất khen thưởng cuối năm (BE `RewardClassRow`).
@immutable
class RewardClassRow {
  const RewardClassRow({
    required this.classId,
    required this.className,
    required this.children,
    this.status,
    this.awarded,
    this.submittedAt,
  });

  final String classId;
  final String className;

  /// Số trẻ của lớp.
  final int children;

  /// Trẻ được đề xuất; null khi BE không trả.
  final int? awarded;

  /// Null ⇒ lớp chưa lập danh sách.
  final RewardStatus? status;
  final DateTime? submittedAt;
}

abstract interface class TeacherRewardSource {
  /// Chi tiết danh sách khen thưởng cuối năm của một lớp.
  Future<TeacherRewards> load(String classId);

  /// Bảng phiếu của lớp; [periodStart] null ⇒ kỳ mới nhất.
  Future<TicketBoard> loadBoard(
    String classId,
    TicketKind kind, {
    DateTime? periodStart,
  });

  /// Tổng hợp phiếu theo trẻ; [month] null ⇒ cả năm học.
  Future<TicketSummary> loadSummary(String classId, {DateTime? month});

  /// Đề xuất khen thưởng cuối năm theo lớp.
  Future<List<RewardClassRow>> loadClasses();
}

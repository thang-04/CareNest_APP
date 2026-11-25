import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';

/// Cờ của một ngày học: cô cắm trong đánh giá ngày, chỉ ngày bé có mặt, mỗi ngày tối đa 1 cờ (OBS-10).
enum FlagDayStatus { flagged, noFlag, absent, pending }

class FlagDay {
  const FlagDay({required this.date, required this.status});

  final DateTime date;
  final FlagDayStatus status;
}

/// Phiếu cô đã phát; không sửa, không thu hồi (OBS-10).
class IssuedTicket {
  const IssuedTicket({required this.issuedBy, required this.issuedAt});

  final String issuedBy;
  final DateTime issuedAt;
}

/// Một tuần học: số cờ BE đếm, cờ từng ngày (chỉ tuần mới nhất), phiếu Bé ngoan nếu cô đã phát.
class RewardWeek {
  const RewardWeek({
    required this.from,
    required this.to,
    required this.flags,
    this.days = const [],
    this.ticket,
    this.ongoing = false,
  });

  final DateTime from;
  final DateTime to;
  final int flags;
  final List<FlagDay> days;
  final IssuedTicket? ticket;

  /// Tuần chưa kết thúc: cô chưa xét phiếu.
  final bool ongoing;
}

enum WeekTicketStatus { issued, none, ongoing }

/// Một tuần trong tháng: đã có phiếu Bé ngoan, không có, hay đang diễn ra.
class WeekTicketSlot {
  const WeekTicketSlot({required this.from, required this.status});

  final DateTime from;
  final WeekTicketStatus status;
}

/// Một tháng: số phiếu Bé ngoan BE đếm, phiếu Bé ngoan toàn diện nếu cô đã phát.
class RewardMonth {
  const RewardMonth({
    required this.month,
    required this.weeklyTickets,
    this.weeks = const [],
    this.ticket,
    this.ongoing = false,
  });

  /// Ngày đầu tháng
  final DateTime month;
  final int weeklyTickets;

  /// Chỉ tháng mới nhất có ô từng tuần.
  final List<WeekTicketSlot> weeks;
  final IssuedTicket? ticket;
  final bool ongoing;
}

/// Khen thưởng cuối năm Hiệu trưởng đã duyệt (OBS-14, PAR-03). [titles] rỗng: bé không có danh hiệu.
class YearEndReward {
  const YearEndReward({
    required this.titles,
    this.approvedAt,
    this.teacherNote,
  });

  final List<String> titles;

  /// BE phụ huynh chưa trả ngày duyệt ⇒ null, màn ẩn dòng duyệt.
  final DateTime? approvedAt;

  /// Ghi chú của cô trong danh sách khen thưởng; phụ huynh xem được (user 18/11).
  final String? teacherNote;
}

/// Tổng cả năm học tới [asOf], BE đếm.
class RewardTotals {
  const RewardTotals({
    required this.flags,
    required this.weeklyTickets,
    required this.monthlyTickets,
    required this.asOf,
  });

  final int flags;
  final int weeklyTickets;
  final int monthlyTickets;
  final DateTime asOf;
}

/// Ngưỡng BE trả (WEEK_MIN_FLAGS, MONTH_MIN_WEEKLY_TICKETS); App không ghi cứng.
class RewardRules {
  const RewardRules({
    required this.weekMinFlags,
    required this.monthMinWeeklyTickets,
  });

  final int weekMinFlags;
  final int monthMinWeeklyTickets;
}

class RewardBook {
  const RewardBook({
    this.schoolYear,
    this.rules,
    this.weeks = const [],
    this.months = const [],
    this.yearEnd,
    this.totals,
  });

  /// "2026–2027"; BE phụ huynh chưa trả ⇒ null, màn ẩn.
  final String? schoolYear;

  /// BE phụ huynh chưa trả ngưỡng ⇒ null, màn ẩn câu quy tắc và nút giải thích (user 25/11, Q2).
  final RewardRules? rules;

  /// Mới nhất trước
  final List<RewardWeek> weeks;

  /// Mới nhất trước
  final List<RewardMonth> months;

  /// null: danh sách khen thưởng của lớp chưa được duyệt
  final YearEndReward? yearEnd;
  final RewardTotals? totals;
}

abstract interface class RewardSource {
  Future<RewardBook> load(String childId, {ChildSchoolYear? year});
}

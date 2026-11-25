import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';

/// Khen thưởng từ BE (OBS-36): `GET /children/{id}/rewards` 8 tuần gần nhất — cờ từng ngày,
/// phiếu tuần / tháng cô đã phát, danh hiệu cuối năm đã duyệt. BE chưa trả ngưỡng, tên năm học,
/// tổng cả năm ⇒ null (màn ẩn, Q2).
class LiveRewardSource implements RewardSource {
  LiveRewardSource(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final DateTime Function() _clock;

  @override
  Future<RewardBook> load(String childId) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    late DateTime from;
    // Đầu năm học: 8 tuần trước có thể trước khai giảng (BE 4109) ⇒ thu hẹp
    final data =
        await loadFromNearestStart(recentStarts(today), (start) {
              from = start;
              return _api.json(
                'GET',
                '/children/$childId/rewards'
                    '?from=${apiDate(start)}&to=${apiDate(today)}',
              );
            })
            as Map? ??
        const {};
    final tickets = _maps(data['tickets']).toList();
    final weekly = {
      for (final t in tickets)
        if (t['type'] == 'WEEKLY') _date(t['periodStart']): t,
    };
    final monthly = {
      for (final t in tickets)
        if (t['type'] == 'MONTHLY') _date(t['periodStart']): t,
    };
    return RewardBook(
      weeks: _weeksOf(_maps(data['flags']), weekly, today),
      months: _monthsOf(from, today, weekly, monthly),
      yearEnd: switch (_maps(data['yearEndTitles']).lastOrNull) {
        final Map item => YearEndReward(
          titles: [
            for (final title in item['titles'] as List? ?? const []) '$title',
          ],
          teacherNote: item['teacherNote']?.toString(),
        ),
        _ => null,
      },
    );
  }

  static Iterable<Map<Object?, Object?>> _maps(Object? list) =>
      (list as List? ?? const []).whereType<Map>();

  static DateTime _date(Object? value) => DateTime.parse(value! as String);

  static IssuedTicket _ticket(Map<Object?, Object?> ticket) => IssuedTicket(
    issuedBy: ticket['issuedByName']?.toString() ?? '',
    issuedAt: DateTime.parse(ticket['issuedAt']! as String).toLocal(),
  );

  /// Tuần có cờ hoặc có phiếu; mới nhất trước. Số cờ: tuần có phiếu lấy số BE ghi trên phiếu,
  /// tuần chưa có phiếu đếm cờ từng ngày BE trả (mỗi ngày tối đa 1 cờ — OBS-10).
  static List<RewardWeek> _weeksOf(
    Iterable<Map<Object?, Object?>> flags,
    Map<DateTime, Map<Object?, Object?>> weekly,
    DateTime today,
  ) {
    final days = <DateTime, List<FlagDay>>{
      for (final monday in weekly.keys) monday: [],
    };
    for (final flag in flags) {
      final date = _date(flag['date']);
      days
          .putIfAbsent(mondayOf(date), () => [])
          .add(
            FlagDay(
              date: date,
              status: flag['flag'] == true
                  ? FlagDayStatus.flagged
                  : FlagDayStatus.noFlag,
            ),
          );
    }
    final mondays = days.keys.toList()..sort((a, b) => b.compareTo(a));
    final currentMonday = mondayOf(today);
    return [
      for (final monday in mondays)
        RewardWeek(
          from: monday,
          to: DateTime(monday.year, monday.month, monday.day + 4),
          flags:
              (weekly[monday]?['flagCount'] as num?)?.toInt() ??
              days[monday]!
                  .where((d) => d.status == FlagDayStatus.flagged)
                  .length,
          days: days[monday]!..sort((a, b) => a.date.compareTo(b.date)),
          ticket: switch (weekly[monday]) {
            final Map ticket => _ticket(ticket),
            _ => null,
          },
          ongoing: monday == currentMonday,
        ),
    ];
  }

  /// Tháng này luôn có; tháng trước khi khoảng tải bắt đầu từ ngày 1 của nó (đủ phiếu); mới nhất trước,
  /// chỉ tháng mới nhất có ô từng tuần.
  static List<RewardMonth> _monthsOf(
    DateTime from,
    DateTime today,
    Map<DateTime, Map<Object?, Object?>> weekly,
    Map<DateTime, Map<Object?, Object?>> monthly,
  ) {
    final currentMonday = mondayOf(today);
    final months = <RewardMonth>[];
    final current = DateTime(today.year, today.month);
    for (
      var month = current;
      month == current || !month.isBefore(from);
      month = DateTime(month.year, month.month - 1)
    ) {
      final ticket = monthly[month];
      final weeksInMonth = weekly.keys.where(
        (monday) => _inMonth(monday, month),
      );
      months.add(
        RewardMonth(
          month: month,
          // Tháng có phiếu: số BE ghi trên phiếu; chưa có: đếm phiếu tuần cô đã phát trong tháng
          weeklyTickets:
              (ticket?['weeklyTickets'] as num?)?.toInt() ??
              weeksInMonth.length,
          weeks: months.isNotEmpty
              ? const []
              : [
                  for (
                    var monday = _firstWeek(month);
                    _inMonth(monday, month) && !monday.isAfter(currentMonday);
                    monday = DateTime(monday.year, monday.month, monday.day + 7)
                  )
                    WeekTicketSlot(
                      from: monday,
                      status: weekly.containsKey(monday)
                          ? WeekTicketStatus.issued
                          : monday == currentMonday
                          ? WeekTicketStatus.ongoing
                          : WeekTicketStatus.none,
                    ),
                ],
          ticket: ticket == null ? null : _ticket(ticket),
          ongoing: month.year == today.year && month.month == today.month,
        ),
      );
    }
    return months;
  }

  // OBS-10 (Cần 18/11): tuần thuộc tháng chứa thứ Sáu của tuần, như BE xét phiếu tháng
  static bool _inMonth(DateTime monday, DateTime month) {
    final friday = DateTime(monday.year, monday.month, monday.day + 4);
    return friday.year == month.year && friday.month == month.month;
  }

  /// Thứ Hai của tuần đầu tiên thuộc tháng (thứ Sáu đầu tiên của tháng − 4 ngày).
  static DateTime _firstWeek(DateTime month) {
    final firstFriday = DateTime(
      month.year,
      month.month,
      1 + (DateTime.friday - month.weekday + 7) % 7,
    );
    return DateTime(firstFriday.year, firstFriday.month, firstFriday.day - 4);
  }
}

import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/features/parent/parent_home/data/fake_parent_home_source.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';

/// Dữ liệu giả, không phải dữ liệu thật của trẻ (AGENTS.md nguyên tắc 4). Khớp trang Đánh giá:
/// bé Minh Anh (Mầm 3A, cô Hà), bé Bảo Ngọc (Lá 1, cô Thư), hôm nay thứ Sáu 28/05/2027.
class FakeRewardSource implements RewardSource {
  const FakeRewardSource({
    this.mode = FakeMode.data,
    this.delay = const Duration(milliseconds: 300),
  });

  final FakeMode mode;
  final Duration delay;

  @override
  Future<RewardBook> load(String childId, {ChildSchoolYear? year}) async {
    await Future<void>.delayed(delay);
    if (mode == FakeMode.error) throw StateError('Không tải được dữ liệu giả');
    if (mode == FakeMode.empty) {
      return const RewardBook(schoolYear: _schoolYear, rules: _rules);
    }
    return childId == 'child-2' ? _baoNgoc() : _minhAnh();
  }
}

const _schoolYear = '2026–2027';
const _rules = RewardRules(weekMinFlags: 3, monthMinWeeklyTickets: 3);
const _teacherHa = 'Cô Trần Thu Hà';
const _teacherThu = 'Cô Vũ Minh Thư';

DateTime _d(int month, int day, [int year = 2027]) =>
    DateTime(year, month, day);

/// Tuần đã kết thúc: thứ Hai [month]/[day] tới thứ Sáu; [issuedOn] = ngày cô phát phiếu.
RewardWeek _week(
  int month,
  int day,
  int flags, {
  String? issuedBy,
  DateTime? issuedOn,
  int year = 2027,
}) {
  final from = _d(month, day, year);
  return RewardWeek(
    from: from,
    to: from.add(const Duration(days: 4)),
    flags: flags,
    ticket: issuedOn == null
        ? null
        : IssuedTicket(issuedBy: issuedBy!, issuedAt: issuedOn),
  );
}

RewardMonth _month(
  int month,
  int weeklyTickets, {
  String? issuedBy,
  DateTime? issuedOn,
  int year = 2027,
}) {
  return RewardMonth(
    month: _d(month, 1, year),
    weeklyTickets: weeklyTickets,
    ticket: issuedOn == null
        ? null
        : IssuedTicket(issuedBy: issuedBy!, issuedAt: issuedOn),
  );
}

List<FlagDay> _days(DateTime monday, List<FlagDayStatus> statuses) => [
  for (var i = 0; i < statuses.length; i++)
    FlagDay(
      date: monday.add(Duration(days: i)),
      status: statuses[i],
    ),
];

RewardBook _minhAnh() {
  const t = _teacherHa;
  return RewardBook(
    schoolYear: _schoolYear,
    rules: _rules,
    weeks: [
      // Cờ từng ngày khớp đánh giá ngày tuần 35 của trang Đánh giá
      RewardWeek(
        from: _d(5, 24),
        to: _d(5, 28),
        flags: 3,
        ongoing: true,
        days: _days(_d(5, 24), const [
          FlagDayStatus.flagged,
          FlagDayStatus.flagged,
          FlagDayStatus.noFlag,
          FlagDayStatus.absent,
          FlagDayStatus.flagged,
        ]),
      ),
      _week(5, 17, 2),
      _week(5, 10, 3, issuedBy: t, issuedOn: _d(5, 17)),
      _week(5, 3, 4, issuedBy: t, issuedOn: _d(5, 10)),
      _week(4, 26, 3, issuedBy: t, issuedOn: _d(5, 3)),
      _week(4, 19, 4, issuedBy: t, issuedOn: _d(4, 26)),
      _week(4, 12, 2),
      _week(4, 5, 3, issuedBy: t, issuedOn: _d(4, 12)),
      _week(3, 29, 3, issuedBy: t, issuedOn: _d(4, 5)),
      _week(3, 22, 4, issuedBy: t, issuedOn: _d(3, 29)),
      _week(3, 15, 3, issuedBy: t, issuedOn: _d(3, 22)),
      _week(3, 8, 3, issuedBy: t, issuedOn: _d(3, 15)),
      _week(3, 1, 1),
    ],
    months: [
      RewardMonth(
        month: _d(5, 1),
        weeklyTickets: 2,
        ongoing: true,
        weeks: [
          WeekTicketSlot(from: _d(5, 3), status: WeekTicketStatus.issued),
          WeekTicketSlot(from: _d(5, 10), status: WeekTicketStatus.issued),
          WeekTicketSlot(from: _d(5, 17), status: WeekTicketStatus.none),
          WeekTicketSlot(from: _d(5, 24), status: WeekTicketStatus.ongoing),
        ],
      ),
      _month(4, 3, issuedBy: t, issuedOn: _d(5, 3)),
      _month(3, 4, issuedBy: t, issuedOn: _d(4, 5)),
      _month(2, 2),
      _month(1, 3, issuedBy: t, issuedOn: _d(2, 1)),
      _month(12, 4, issuedBy: t, issuedOn: _d(1, 4), year: 2026),
      _month(11, 3, issuedBy: t, issuedOn: _d(12, 1, 2026), year: 2026),
      _month(10, 2, year: 2026),
      _month(9, 1, year: 2026),
    ],
    yearEnd: YearEndReward(
      titles: const ['Bé chăm ngoan xuất sắc', 'Cháu ngoan Bác Hồ'],
      approvedAt: _d(5, 28),
      teacherNote:
          'Con đi học đều, luôn vui vẻ giúp đỡ bạn và mạnh dạn phát biểu '
          'trước lớp.',
    ),
    totals: RewardTotals(
      flags: 92,
      weeklyTickets: 24,
      monthlyTickets: 5,
      asOf: _d(5, 28),
    ),
  );
}

RewardBook _baoNgoc() {
  const t = _teacherThu;
  return RewardBook(
    schoolYear: _schoolYear,
    rules: _rules,
    weeks: [
      RewardWeek(
        from: _d(5, 24),
        to: _d(5, 28),
        flags: 4,
        ongoing: true,
        days: _days(_d(5, 24), const [
          FlagDayStatus.flagged,
          FlagDayStatus.flagged,
          FlagDayStatus.flagged,
          FlagDayStatus.noFlag,
          FlagDayStatus.flagged,
        ]),
      ),
      _week(5, 17, 3, issuedBy: t, issuedOn: _d(5, 24)),
      _week(5, 10, 4, issuedBy: t, issuedOn: _d(5, 17)),
      _week(5, 3, 3, issuedBy: t, issuedOn: _d(5, 10)),
    ],
    months: [
      RewardMonth(
        month: _d(5, 1),
        weeklyTickets: 3,
        ongoing: true,
        weeks: [
          WeekTicketSlot(from: _d(5, 3), status: WeekTicketStatus.issued),
          WeekTicketSlot(from: _d(5, 10), status: WeekTicketStatus.issued),
          WeekTicketSlot(from: _d(5, 17), status: WeekTicketStatus.issued),
          WeekTicketSlot(from: _d(5, 24), status: WeekTicketStatus.ongoing),
        ],
      ),
      _month(4, 4, issuedBy: t, issuedOn: _d(5, 3)),
      _month(3, 3, issuedBy: t, issuedOn: _d(4, 5)),
    ],
    yearEnd: YearEndReward(
      titles: const [
        'Bé chăm ngoan',
        'Hoàn thành tốt chương trình giáo dục mầm non',
      ],
      approvedAt: _d(5, 28),
      teacherNote:
          'Con chăm chỉ, khéo tay và luôn giúp cô xếp đồ chơi. Chúc con tự tin '
          'bước vào lớp 1!',
    ),
    totals: RewardTotals(
      flags: 98,
      weeklyTickets: 27,
      monthlyTickets: 6,
      asOf: _d(5, 28),
    ),
  );
}

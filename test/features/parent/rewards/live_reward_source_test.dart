import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/rewards/data/live_reward_source.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;
  // Thứ Tư; 8 tuần gần nhất tính từ thứ Hai 7 tuần trước
  final today = DateTime(2026, 11, 25);
  const path = 'GET /children/5/rewards?from=2026-10-05&to=2026-11-25';

  setUp(() => session = FakeLiveSession(['PARENT'], childIds: [5]));

  Future<RewardBook> load({
    List<Object> flags = const [],
    List<Object> tickets = const [],
    List<Object> titles = const [],
  }) => LiveRewardSource(
    ScriptedApi(session, {
      path: (_) => {
        'childId': 5,
        'flags': flags,
        'tickets': tickets,
        'yearEndTitles': titles,
      },
    }),
    clock: () => today,
  ).load('5');

  Map<String, Object?> weekly(String start, String end, {int? flagCount}) => {
    'type': 'WEEKLY',
    'periodStart': start,
    'periodEnd': end,
    'flagCount': flagCount,
    'issuedByName': 'Cô Hà',
    'issuedAt': '${end}T09:00:00Z',
  };

  test('load_weeklyFlagsAndTickets', () async {
    final book = await load(
      flags: [
        {'date': '2026-11-17', 'flag': true},
        {'date': '2026-11-23', 'flag': true},
        {'date': '2026-11-24', 'flag': false},
      ],
      tickets: [weekly('2026-11-16', '2026-11-20', flagCount: 4)],
    );

    // Q2: BE chưa trả ngưỡng, tên năm học ⇒ ẩn
    expect(book.rules, isNull);
    expect(book.schoolYear, isNull);
    expect(book.weeks.map((w) => w.from), [
      DateTime(2026, 11, 23),
      DateTime(2026, 11, 16),
    ]);
    final current = book.weeks.first;
    expect(current.to, DateTime(2026, 11, 27));
    expect(current.ongoing, isTrue);
    expect(current.flags, 1);
    expect(current.days.map((d) => d.status), [
      FlagDayStatus.flagged,
      FlagDayStatus.noFlag,
    ]);
    expect(current.ticket, isNull);

    final last = book.weeks.last;
    expect(last.ongoing, isFalse);
    // Tuần đã có phiếu: số cờ là số BE ghi trên phiếu
    expect(last.flags, 4);
    expect(last.ticket!.issuedBy, 'Cô Hà');
    expect(last.ticket!.issuedAt, DateTime.utc(2026, 11, 20, 9).toLocal());
  });

  test('load_monthlyTicket', () async {
    final book = await load(
      tickets: [
        weekly('2026-11-16', '2026-11-20'),
        {
          'type': 'MONTHLY',
          'periodStart': '2026-11-01',
          'periodEnd': '2026-11-30',
          'weeklyTickets': 3,
          'issuedByName': 'Cô Hà',
          'issuedAt': '2026-11-25T09:00:00Z',
        },
      ],
    );

    // Tháng 10 bắt đầu trước khoảng tải (05/10) ⇒ không đủ phiếu, không hiện
    final month = book.months.single;
    expect(month.month, DateTime(2026, 11));
    expect(month.ongoing, isTrue);
    expect(month.weeklyTickets, 3);
    expect(month.ticket!.issuedBy, 'Cô Hà');
    expect(month.weeks.map((w) => '${w.from.day}:${w.status.name}'), [
      '2:none',
      '9:none',
      '16:issued',
      '23:ongoing',
    ]);
  });

  test('load_monthWithoutTicket_countsWeeklyTickets', () async {
    final book = await load(tickets: [weekly('2026-11-16', '2026-11-20')]);

    expect(book.months.single.weeklyTickets, 1);
    expect(book.months.single.ticket, isNull);
  });

  test('load_yearEndTitles', () async {
    final book = await load(
      titles: [
        {
          'titles': ['Bé chăm ngoan'],
          'teacherNote': 'Con lễ phép.',
        },
      ],
    );

    expect(book.yearEnd!.titles, ['Bé chăm ngoan']);
    expect(book.yearEnd!.teacherNote, 'Con lễ phép.');
    expect(book.yearEnd!.approvedAt, isNull);
  });

  test('load_noYearEndTitles_null', () async {
    final book = await load();

    expect(book.yearEnd, isNull);
    expect(book.weeks, isEmpty);
  });
}

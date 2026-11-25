import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/rewards/data/live_reward_source.dart';
import 'package:carenest_app/features/parent/rewards/domain/rewards.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;
  // Thứ Tư; 8 tuần gần nhất, lùi tới ngày 1 tháng trước để có phiếu tháng trước
  final today = DateTime(2026, 11, 25);
  const path = 'GET /children/5/rewards?from=2026-10-01&to=2026-11-25';

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

    final month = book.months.first;
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

    expect(book.months.first.weeklyTickets, 1);
    expect(book.months.first.ticket, isNull);
  });

  test('load_weekBelongsToMonthOfItsFriday', () async {
    // OBS-10 (Cần 18/11): tuần T2 28/9 – T6 2/10 thuộc tháng 10
    final october = DateTime(2026, 10, 7);
    final book = await LiveRewardSource(
      ScriptedApi(session, {
        'GET /children/5/rewards?from=2026-08-17&to=2026-10-07': (_) => {
          'flags': <Object>[],
          'tickets': [weekly('2026-09-28', '2026-10-02')],
          'yearEndTitles': <Object>[],
        },
      }),
      clock: () => october,
    ).load('5');

    expect(book.months.first.month, DateTime(2026, 10));
    expect(book.months.first.weeklyTickets, 1);
    expect(
      book.months.first.weeks.map(
        (w) => '${w.from.month}/${w.from.day}:${w.status.name}',
      ),
      ['9/28:issued', '10/5:ongoing'],
    );
    expect(book.months[1].month, DateTime(2026, 9));
    expect(book.months[1].weeklyTickets, 0);
  });

  test('load_previousMonthTicketShown', () async {
    final book = await load(
      tickets: [
        {
          'type': 'MONTHLY',
          'periodStart': '2026-10-01',
          'periodEnd': '2026-10-31',
          'weeklyTickets': 4,
          'issuedByName': 'Cô Hà',
          'issuedAt': '2026-11-03T09:00:00Z',
        },
      ],
    );

    expect(book.months.map((m) => m.month), [
      DateTime(2026, 11),
      DateTime(2026, 10),
    ]);
    expect(book.months.last.weeklyTickets, 4);
    expect(book.months.last.ticket!.issuedBy, 'Cô Hà');
  });

  test('load_yearStartFallback_keepsCurrentMonth', () async {
    // Đầu năm học: khoảng dài lấn trước khai giảng ⇒ BE 4109, App lùi dần về tuần này
    Never reject(Object? _) =>
        throw ApiFailure(400, 'Chọn khoảng ngày trong một năm học', 4109);
    final book = await LiveRewardSource(
      ScriptedApi(session, {
        path: reject,
        'GET /children/5/rewards?from=2026-10-05&to=2026-11-25': reject,
        'GET /children/5/rewards?from=2026-11-01&to=2026-11-25': reject,
        'GET /children/5/rewards?from=2026-11-23&to=2026-11-25': (_) => {
          'flags': <Object>[],
          'tickets': <Object>[],
          'yearEndTitles': <Object>[],
        },
      }),
      clock: () => today,
    ).load('5');

    expect(book.months.single.month, DateTime(2026, 11));
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

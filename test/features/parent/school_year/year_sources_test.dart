import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/evaluation/data/live_evaluation_source.dart';
import 'package:carenest_app/features/parent/health_book/data/live_health_book_source.dart';
import 'package:carenest_app/features/parent/my_child/data/live_my_child_source.dart';
import 'package:carenest_app/features/parent/rewards/data/live_reward_source.dart';
import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';

import '../../../helpers/live_fakes.dart';

final _active = ChildSchoolYear(
  id: '3',
  label: '2026–2027',
  startDate: DateTime(2026, 9, 1),
  endDate: DateTime(2027, 5, 31),
  status: ChildSchoolYearStatus.active,
  className: 'Mầm 1',
);

final _closed = ChildSchoolYear(
  id: '2',
  label: '2025–2026',
  startDate: DateTime(2025, 9, 1),
  endDate: DateTime(2026, 5, 31),
  status: ChildSchoolYearStatus.closed,
  className: 'Nhà trẻ 1',
);

final _planned = ChildSchoolYear(
  id: '4',
  label: '2027–2028',
  startDate: DateTime(2027, 9, 1),
  endDate: DateTime(2028, 5, 31),
  status: ChildSchoolYearStatus.planned,
  className: 'Chồi 1',
);

void main() {
  final today = DateTime(2026, 11, 25);
  late FakeLiveSession session;

  setUp(() => session = FakeLiveSession(['PARENT'], childIds: [5]));

  group('ChildSchoolYear ranges (ATT-15)', () {
    test('recentRange_activeYear_endsTodayNotBeforeStart', () {
      final range = _active.recentRange(DateTime(2026, 9, 20))!;
      expect(range.from, DateTime(2026, 9, 1));
      expect(range.to, DateTime(2026, 9, 20));
    });

    test('recentRange_closedYear_endsAtYearEnd', () {
      final range = _closed.recentRange(today)!;
      expect(range.to, DateTime(2026, 5, 31));
      expect(range.from.isBefore(range.to), isTrue);
      expect(range.to.difference(range.from).inDays, lessThan(62));
    });

    test('ranges_futureYear_areNull', () {
      expect(_planned.recentRange(today), isNull);
      expect(_planned.monthRange(today), isNull);
    });

    test('monthRange_closedYear_isLastMonth', () {
      final range = _closed.monthRange(today)!;
      expect(range.from, DateTime(2026, 5, 1));
      expect(range.to, DateTime(2026, 5, 31));
    });
  });

  test('rewards_closedYear_queriesInsideYear', () async {
    final api = ScriptedApi(session, {
      'GET /children/5/rewards?from=2026-04-01&to=2026-05-31': (_) => {
        'tickets': [],
        'days': [],
      },
    });
    await LiveRewardSource(api, clock: () => today).load('5', year: _closed);
    expect(api.calls, [
      'GET /children/5/rewards?from=2026-04-01&to=2026-05-31',
    ]);
  });

  test('evaluation_year_passesSchoolYearId', () async {
    final api = ScriptedApi(session, {
      'GET /children/5/daily-assessments?from=2026-04-01&to=2026-05-31': (_) =>
          [],
      'GET /children/5/weekly-comments?schoolYearId=2': (_) => [],
      'GET /children/5/evaluations?schoolYearId=2': (_) => {},
    });
    await LiveEvaluationSource(
      api,
      clock: () => today,
    ).load('5', year: _closed);
    expect(api.calls, hasLength(3));
  });

  test('evaluation_futureYear_skipsDailyRange', () async {
    final api = ScriptedApi(session, {
      'GET /children/5/weekly-comments?schoolYearId=4': (_) => [],
      'GET /children/5/evaluations?schoolYearId=4': (_) => {},
    });
    final book = await LiveEvaluationSource(
      api,
      clock: () => today,
    ).load('5', year: _planned);
    expect(book.weeks, isEmpty);
  });

  test('healthBook_year_passesSchoolYearId', () async {
    final api = ScriptedApi(session, {
      'GET /children/5/health/published?schoolYearId=2': (_) => {'results': []},
    });
    final book = await LiveHealthBookSource(api).load('5', year: _closed);
    expect(book.rounds, isEmpty);
  });

  test('attendance_closedYear_loadsLastMonth', () async {
    final api = ScriptedApi(session, {
      'GET /children/5/attendance?from=2026-05-01&to=2026-05-31': (_) => {
        'totals': {'present': 3},
        'days': [],
      },
      'GET /children/5/daily-health/parent?from=2026-05-01&to=2026-05-31':
          (_) => [],
    });
    final month = await LiveMyChildSource(
      api,
      clock: () => today,
    ).loadAttendance('5', year: _closed);
    expect(month.month, DateTime(2026, 5));
    expect(month.presentCount, 3);
  });
}

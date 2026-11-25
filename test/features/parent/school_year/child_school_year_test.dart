import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/parent/school_year/data/live_child_school_year_source.dart';
import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';
import 'package:carenest_app/features/parent/school_year/presentation/parent_selected_year.dart';

import '../../../helpers/live_fakes.dart';

ChildSchoolYear _year(String id, ChildSchoolYearStatus status, int startYear) =>
    ChildSchoolYear(
      id: id,
      label: '$startYear-${startYear + 1}',
      startDate: DateTime(startYear, 9, 1),
      endDate: DateTime(startYear + 1, 5, 31),
      status: status,
      className: 'Lớp $id',
    );

void main() {
  tearDown(ParentSelectedYear.reset);

  test('live_mapsYearsOfChild', () async {
    final session = FakeLiveSession(['PARENT'], childIds: [5]);
    final years = await LiveChildSchoolYearSource(
      ScriptedApi(session, {
        'GET /children/5/school-years': (_) => [
          {
            'schoolYearId': 3,
            'name': '2026-2027',
            'startDate': '2026-09-01',
            'endDate': '2027-05-31',
            'status': 'ACTIVE',
            'className': 'Mầm 1',
          },
          {
            'schoolYearId': 2,
            'name': '2025-2026',
            'startDate': '2025-09-01',
            'endDate': '2026-05-31',
            'status': 'CLOSED',
            'className': 'Nhà trẻ 1',
          },
        ],
      }),
    ).loadYears('5');

    expect(years.map((y) => y.id), ['3', '2']);
    expect(years.first.label, '2026–2027');
    expect(years.first.startDate, DateTime(2026, 9, 1));
    expect(years.first.readOnly, isFalse);
    expect(years.last.status, ChildSchoolYearStatus.closed);
    expect(years.last.readOnly, isTrue);
    expect(years.last.className, 'Nhà trẻ 1');
  });

  test('selected_defaultsToActiveYear', () {
    final years = [
      _year('4', ChildSchoolYearStatus.planned, 2027),
      _year('3', ChildSchoolYearStatus.active, 2026),
      _year('2', ChildSchoolYearStatus.closed, 2025),
    ];
    expect(ParentSelectedYear.of('5', years)?.id, '3');
  });

  test('selected_noActiveYear_defaultsToNewestPast', () {
    final years = [
      _year('2', ChildSchoolYearStatus.closed, 2025),
      _year('1', ChildSchoolYearStatus.closed, 2024),
    ];
    expect(ParentSelectedYear.of('5', years)?.id, '2');
    expect(ParentSelectedYear.of('5', const []), isNull);
  });

  test('selected_keptPerChild_resetOnLogout', () {
    final years = [
      _year('3', ChildSchoolYearStatus.active, 2026),
      _year('2', ChildSchoolYearStatus.closed, 2025),
    ];
    ParentSelectedYear.select('5', '2');
    expect(ParentSelectedYear.of('5', years)?.id, '2');
    // Bé khác chưa chọn ⇒ năm mặc định của bé đó
    expect(ParentSelectedYear.of('6', years)?.id, '3');

    ParentSelectedYear.reset();
    expect(ParentSelectedYear.of('5', years)?.id, '3');
  });

  test('selected_yearNoLongerListed_fallsBackToDefault', () {
    ParentSelectedYear.select('5', '9');
    expect(
      ParentSelectedYear.of('5', [
        _year('3', ChildSchoolYearStatus.active, 2026),
      ])?.id,
      '3',
    );
  });
}

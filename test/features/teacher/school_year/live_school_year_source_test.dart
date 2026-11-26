import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/features/teacher/school_year/data/live_school_year_source.dart';
import 'package:carenest_app/features/teacher/school_year/domain/school_year.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  test('loadYears_mapsStatusLabelAndClass', () async {
    // Năm 1 không có route cấu trúc trường ⇒ lỗi 404, tên lớp trống
    final api = ScriptedApi(FakeLiveSession(['TEACHER']), {
      'GET /school-years': (_) => [
        {'id': 2, 'name': '2026-2027', 'status': 'ACTIVE'},
        {'id': 1, 'name': '2025-2026', 'status': 'CLOSED'},
      ],
      'GET /school-structure?schoolYearId=2': (_) => {
        'classes': [
          {'id': 12, 'name': 'Mầm 3A'},
        ],
      },
    });
    final years = await LiveSchoolYearSource(api).loadYears();
    expect(years.map((y) => y.label), ['2026–2027', '2025–2026']);
    expect(years[0].status, SchoolYearStatus.active);
    expect(years[0].className, 'Mầm 3A');
    expect(years[1].readOnly, isTrue);
    expect(years[1].className, '');
  });
}

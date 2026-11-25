import 'package:carenest_app/features/teacher/class_roster/data/fake_class_roster_source.dart';
import 'package:carenest_app/features/teacher/school_year/domain/school_year.dart';

/// Năm học giả: năm đang chạy (Mầm 3A) và năm trước đã đóng (Nhà trẻ 2) — AUTH-03.
class FakeSchoolYearSource implements SchoolYearSource {
  const FakeSchoolYearSource();

  static const years = [
    SchoolYear(
      id: 'sy-2026',
      label: '2026–2027',
      status: SchoolYearStatus.active,
      className: FakeClassRosterSource.className,
    ),
    SchoolYear(
      id: 'sy-2025',
      label: '2025–2026',
      status: SchoolYearStatus.closed,
      className: 'Nhà trẻ 2',
    ),
  ];

  @override
  Future<List<SchoolYear>> loadYears() async => years;
}

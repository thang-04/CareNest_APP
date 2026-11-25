import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';

/// Năm học giả (Xem thử): năm đang chạy và năm trước đã đóng.
class FakeChildSchoolYearSource implements ChildSchoolYearSource {
  const FakeChildSchoolYearSource();

  static final years = [
    ChildSchoolYear(
      id: 'sy-2026',
      label: '2026–2027',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2027, 5, 31),
      status: ChildSchoolYearStatus.active,
      className: 'Mầm 3A',
    ),
    ChildSchoolYear(
      id: 'sy-2025',
      label: '2025–2026',
      startDate: DateTime(2025, 9, 1),
      endDate: DateTime(2026, 5, 31),
      status: ChildSchoolYearStatus.closed,
      className: 'Nhà trẻ 2',
    ),
  ];

  @override
  Future<List<ChildSchoolYear>> loadYears(String childId) async => years;
}

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/school_year/domain/child_school_year.dart';

/// Năm học của bé từ BE: `GET /children/{id}/school-years` (mới trước).
class LiveChildSchoolYearSource implements ChildSchoolYearSource {
  const LiveChildSchoolYearSource(this._api);

  final MobileApi _api;

  @override
  Future<List<ChildSchoolYear>> loadYears(String childId) async {
    final data = await _api.json('GET', '/children/$childId/school-years');
    return [
      for (final item in (data as List? ?? const []).whereType<Map>())
        ChildSchoolYear(
          id: '${item['schoolYearId']}',
          // BE ghi "2026-2027"; App hiện gạch ngang dài như ô năm học GV
          label: '${item['name'] ?? ''}'.replaceAll('-', '–'),
          startDate: DateTime.parse('${item['startDate']}'),
          endDate: DateTime.parse('${item['endDate']}'),
          status: switch (item['status']) {
            'ACTIVE' => ChildSchoolYearStatus.active,
            'PLANNED' => ChildSchoolYearStatus.planned,
            _ => ChildSchoolYearStatus.closed,
          },
          className: '${item['className'] ?? ''}',
        ),
    ];
  }
}

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/school_year/domain/school_year.dart';

/// Năm học của GV từ BE: `GET /school-years` (GV nhận các năm xem được) và tên lớp GV dạy trong từng năm
/// `GET /school-structure?schoolYearId=` (BE chỉ trả lớp trong phạm vi GV). Lỗi riêng một năm ⇒ tên lớp trống.
class LiveSchoolYearSource implements SchoolYearSource {
  LiveSchoolYearSource(this._api);

  final MobileApi _api;

  @override
  Future<List<SchoolYear>> loadYears() async {
    final data = await _api.json('GET', '/school-years') as List? ?? const [];
    return Future.wait([for (final item in data.whereType<Map>()) _year(item)]);
  }

  Future<SchoolYear> _year(Map<Object?, Object?> item) async {
    final id = '${item['id']}';
    return SchoolYear(
      id: id,
      label: _label(item),
      status: switch (item['status']) {
        'ACTIVE' => SchoolYearStatus.active,
        'PLANNED' => SchoolYearStatus.planned,
        _ => SchoolYearStatus.closed,
      },
      className: await _className(id),
    );
  }

  /// BE đặt tên năm học dạng "2026-2027"; hiển thị bằng gạch nối dài như Web.
  static String _label(Map<Object?, Object?> item) =>
      '${item['name'] ?? ''}'.replaceAll('-', '–');

  Future<String> _className(String yearId) async {
    try {
      final data =
          await _api.json('GET', '/school-structure?schoolYearId=$yearId')
              as Map? ??
          const {};
      final classes = (data['classes'] as List? ?? const []).whereType<Map>();
      return classes.map((c) => '${c['name'] ?? ''}').join(', ');
    } on ApiFailure {
      return '';
    }
  }
}

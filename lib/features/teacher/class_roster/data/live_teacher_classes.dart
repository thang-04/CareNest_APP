import 'package:flutter/foundation.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';

/// Lớp trong năm học người dùng xem được — `GET /attendance/classes` (`AttendanceClassResponse`).
@immutable
class TeacherClass {
  const TeacherClass({
    required this.id,
    required this.name,
    this.campusId,
    this.teaches = false,
    this.canRecord = false,
    this.historicalReadOnly = false,
  });

  final String id;
  final String name;
  final String? campusId;

  /// Giáo viên được phân công lớp này.
  final bool teaches;

  /// BE: `teaches` và năm học đang hoạt động.
  final bool canRecord;
  final bool historicalReadOnly;
}

/// Lớp của giáo viên đăng nhập; lớp được phân công (`teaches`) xếp trước. Router dùng để lấy `classId`.
///
/// [schoolYearId] null ⇒ năm đang chạy; id khác ⇒ lớp của năm đó (năm đã đóng: `historicalReadOnly`).
Future<List<TeacherClass>> loadTeacherClasses(
  MobileApi api, {
  String? schoolYearId,
}) async {
  final query = schoolYearId == null ? '' : '?schoolYearId=$schoolYearId';
  final data = await api.json('GET', '/attendance/classes$query');
  final classes = [
    for (final item in (data as List? ?? const []).whereType<Map>())
      TeacherClass(
        id: '${item['id']}',
        name: item['name']?.toString() ?? '',
        campusId: item['campusId']?.toString(),
        teaches: item['teaches'] == true,
        canRecord: item['canRecord'] == true,
        historicalReadOnly: item['historicalReadOnly'] == true,
      ),
  ];
  // sort ổn định: giữ thứ tự BE trong mỗi nhóm
  return [
    ...classes.where((c) => c.teaches),
    ...classes.where((c) => !c.teaches),
  ];
}

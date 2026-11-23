import 'package:flutter/foundation.dart';

/// `SchoolYear.status` BE: PLANNED / ACTIVE / CLOSED.
enum SchoolYearStatus { planned, active, closed }

/// Năm học GV xem được (`GET /school-years`): năm có phân công, năm PLANNED chỉ từ ngày chuẩn bị.
@immutable
class SchoolYear {
  const SchoolYear({
    required this.id,
    required this.label,
    required this.status,
    required this.className,
  });

  final String id;

  /// "2026–2027"
  final String label;
  final SchoolYearStatus status;

  /// Lớp GV được phân công trong năm đó (`/school-structure?schoolYearId`).
  final String className;

  /// AUTH-03: năm đã đóng chỉ xem; việc theo ngày luôn ở năm đang chạy (như Web).
  bool get readOnly => status != SchoolYearStatus.active;
}

abstract interface class SchoolYearSource {
  Future<List<SchoolYear>> loadYears();
}

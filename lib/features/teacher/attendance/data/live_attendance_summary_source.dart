import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';
import 'package:carenest_app/features/teacher/attendance/domain/attendance_summary.dart';

/// Tổng hợp điểm danh lớp từ BE: `GET /classes/{classId}/attendance/summary[?from=&to=]`
/// (`AttendanceSummaryResponse.ClassSummary`). Mọi số liệu do BE tính.
class LiveAttendanceSummarySource implements AttendanceSummarySource {
  LiveAttendanceSummarySource(this._api);

  final MobileApi _api;

  @override
  Future<AttendanceSummary> load(
    String classId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final query = [
      if (from != null) 'from=${apiDate(from)}',
      if (to != null) 'to=${apiDate(to)}',
    ].join('&');
    final suffix = query.isEmpty ? '' : '?$query';
    final data =
        await _api.json('GET', '/classes/$classId/attendance/summary$suffix')
            as Map? ??
        const {};
    return AttendanceSummary(
      className: data['className']?.toString() ?? '',
      from: _date(data['from']),
      to: _date(data['to']),
      size: _int(data['size']),
      mealSessions: [
        for (final code in data['mealSessions'] as List? ?? const [])
          ...MealSession.values.where((s) => s.code == code),
      ],
      days: [
        for (final row in (data['days'] as List? ?? const []).whereType<Map>())
          AttendanceSummaryDay(
            date: _date(row['date']),
            present: _int(row['present']),
            excused: _int(row['excused']),
            unexcused: _int(row['unexcused']),
            missing: _int(row['missing']),
            mealTotal: _int(row['mealTotal']),
            meals: _meals(row['meals']),
            morningOff: _int(row['morningOff']),
            afternoonOff: _int(row['afternoonOff']),
          ),
      ],
      children: [
        for (final row
            in (data['children'] as List? ?? const []).whereType<Map>())
          AttendanceSummaryChild(
            childId: '${(row['child'] as Map?)?['id']}',
            fullName: (row['child'] as Map?)?['fullName']?.toString() ?? '',
            attendedDays: (row['attendedDays'] as num?)?.toDouble() ?? 0,
            excused: _int(row['excused']),
            unexcused: _int(row['unexcused']),
            mealDays: _int(row['meals']),
            mealCounts: _meals(row['mealCounts']),
            morningOff: _int(row['morningOff']),
            afternoonOff: _int(row['afternoonOff']),
          ),
      ],
    );
  }

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  static DateTime _date(Object? value) =>
      DateTime.tryParse('$value') ?? DateTime(1970);

  static Map<MealSession, int> _meals(Object? value) {
    final map = value as Map? ?? const {};
    return {
      for (final session in MealSession.values)
        if (map[session.code] case final num count) session: count.toInt(),
    };
  }
}

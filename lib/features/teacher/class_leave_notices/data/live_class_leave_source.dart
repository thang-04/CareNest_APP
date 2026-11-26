import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/class_leave_notices/domain/class_leave_notice.dart';
import 'package:carenest_app/features/teacher/school_year/presentation/selected_school_year.dart';

/// Đơn nghỉ của lớp từ BE: `GET /leave-requests?classId=` (ATTENDANCE_VIEW, GV chỉ xem).
class LiveClassLeaveSource implements ClassLeaveSource {
  LiveClassLeaveSource(
    this._api, {
    DateTime Function()? clock,
    String? Function()? schoolYearId,
  }) : _clock = clock ?? DateTime.now,
       _schoolYearId = schoolYearId ?? (() => SelectedSchoolYear.apiYearId);

  final MobileApi _api;
  final DateTime Function() _clock;
  final String? Function() _schoolYearId;

  @override
  Future<List<ClassLeaveEntry>> load(
    String classId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final range = defaultLeaveRange(_clock());
    final yearId = _schoolYearId();
    final yearQuery = yearId == null ? '' : '&schoolYearId=$yearId';
    final data =
        await _api.json(
              'GET',
              '/leave-requests?classId=$classId&from=${apiDate(from ?? range.$1)}&to=${apiDate(to ?? range.$2)}$yearQuery',
            )
            as List? ??
        const [];
    return [for (final item in data.whereType<Map>()) _entry(item)];
  }

  static ClassLeaveEntry _entry(Map<Object?, Object?> e) => ClassLeaveEntry(
    id: '${e['id']}',
    childId: '${e['childId']}',
    childName: e['childName']?.toString() ?? '',
    fromDate: _date(e['fromDate'])!,
    toDate: _date(e['toDate'])!,
    className: e['className']?.toString() ?? '',
    part: LeavePart.values.firstWhere(
      (p) => p.code == e['part'],
      orElse: () => LeavePart.fullDay,
    ),
    eats: e['eats'] as bool?,
    eatsMeals: [for (final m in e['eatsMeals'] as List? ?? const []) '$m'],
    noticeOnly: e['noticeOnly'] == true,
    effectiveTo: _date(e['effectiveTo']),
    reason: e['reason']?.toString() ?? '',
    status: e['status'] == 'CANCELLED'
        ? LeaveRequestStatus.cancelled
        : LeaveRequestStatus.active,
    createdByName: e['createdByName']?.toString() ?? '',
    createdAt: DateTime.parse(e['createdAt']! as String).toLocal(),
    cancelledAt: switch (e['cancelledAt']) {
      final String at => DateTime.parse(at).toLocal(),
      _ => null,
    },
    appliedDates: _dates(e['appliedDates']),
    skippedDates: _dates(e['skippedDates']),
  );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  static List<DateTime> _dates(Object? value) => [
    for (final d in value as List? ?? const []) DateTime.parse('$d'),
  ];
}

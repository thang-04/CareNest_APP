import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/attendance/data/fake_attendance_source.dart'
    show AttendanceSource;
import 'package:carenest_app/features/teacher/attendance/domain/attendance.dart';

/// Điểm danh lớp/ngày từ BE: `GET /classes/{classId}/attendance[?date=]` (sổ + `day` giờ khóa/ngày học) và
/// `PUT /classes/{classId}/attendance` (upsert idempotent theo lớp/ngày, ATT-01b). `date` null = hôm nay do BE chọn.
/// BE chưa trả tên điểm trường và mã trẻ ⇒ `campusName`, `code` rỗng.
class LiveAttendanceSource implements AttendanceSource {
  LiveAttendanceSource(this._api);

  final MobileApi _api;

  @override
  Future<AttendanceSheet> loadSheet(String classId, {DateTime? date}) async {
    final query = date == null ? '' : '?date=${apiDate(date)}';
    final data =
        await _api.json('GET', '/classes/$classId/attendance$query') as Map? ??
        const {};
    final day = data['day'] as Map? ?? const {};
    final rows = (data['children'] as List? ?? const []).whereType<Map>();
    final sessions = _sessions(data['mealSessions']);
    return AttendanceSheet(
      classSummary: ClassSummary(
        id: classId,
        name: data['className']?.toString() ?? '',
        campusName: '',
        childCount: rows.length,
      ),
      date: DateTime.parse('${day['date']}'),
      today: day['today'] == null ? null : DateTime.parse('${day['today']}'),
      kids: [for (final row in rows) _kid(row)],
      mealSessions: sessions.isEmpty ? MealSession.values : sessions,
      lockAt: day['cutoff']?.toString(),
      canRecord: data['canRecord'] == true,
      locked: day['locked'] == true,
      schoolDay: day['schoolDay'] != false,
    );
  }

  @override
  Future<void> save(
    String classId,
    DateTime date,
    List<KidAttendance> kids,
  ) async {
    final entries = [
      for (final kid in kids)
        if (_statusCode(kid.status) case final code?)
          {
            'childId': int.tryParse(kid.childId) ?? kid.childId,
            'status': code,
            // Vắng thì không ăn bữa nào; BE tự xử lý
            if (kid.status == AttendanceStatus.present)
              'meals': {for (final e in kid.meals.entries) e.key.code: e.value},
          },
    ];
    // BE từ chối `entries` rỗng (400): chưa điểm danh bé nào thì không có gì để lưu
    if (entries.isEmpty) return;
    await _api.json(
      'PUT',
      '/classes/$classId/attendance',
      body: {'date': apiDate(date), 'entries': entries},
    );
  }

  static List<MealSession> _sessions(Object? codes) => [
    for (final code in codes as List? ?? const [])
      ...MealSession.values.where((s) => s.code == code),
  ];

  static List<MealSession> _sessionList(Object? codes) => _sessions(codes);

  static DateTime _day(Object? value) =>
      DateTime.tryParse('$value') ?? DateTime(1970);

  static LeaveNotice? _leave(Map? leave) {
    if (leave == null) return null;
    return LeaveNotice(
      fromDate: _day(leave['fromDate']),
      toDate: _day(leave['toDate']),
      reason: leave['reason']?.toString() ?? '',
      part: DayPartCode.fromCode(leave['part']) ?? DayPartCode.fullDay,
      eats: leave['eats'] as bool?,
      eatsMeals: _sessionList(leave['eatsMeals']),
      noticeOnly: leave['noticeOnly'] == true,
    );
  }

  static KidAttendance _kid(Map<Object?, Object?> row) {
    final child = row['child'] as Map? ?? const {};
    final record = row['record'] as Map?;
    final health = row['health'] as Map? ?? const {};
    final meals = record?['meals'] as Map? ?? const {};
    final absentPart = DayPartCode.fromCode(record?['absentPart']);
    return KidAttendance(
      childId: '${child['id']}',
      fullName: child['fullName']?.toString() ?? '',
      code: child['code']?.toString(),
      hasAllergy: child['hasAllergy'] == true,
      mealRegistered: child['mealRegistered'] != false,
      status: switch (record?['status']) {
        'PRESENT' => AttendanceStatus.present,
        'EXCUSED' => AttendanceStatus.excused,
        'UNEXCUSED' => AttendanceStatus.unexcused,
        _ => AttendanceStatus.notRecorded,
      },
      meals: {
        for (final session in MealSession.values)
          if (meals[session.code] case final bool eats) session: eats,
      },
      leave: _leave(row['leave'] as Map?),
      absentPart: absentPart == DayPartCode.fullDay ? null : absentPart,
      absentPartUnexcused: record?['absentPartUnexcused'] == true,
      health: KidHealthBrief(
        checked: health['checked'] == true,
        noted: health['observation'] == 'NOTED',
        temperature: (health['temperature'] as num?)?.toDouble(),
      ),
    );
  }

  static String? _statusCode(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => 'PRESENT',
    AttendanceStatus.excused => 'EXCUSED',
    AttendanceStatus.unexcused => 'UNEXCUSED',
    AttendanceStatus.notRecorded => null,
  };
}

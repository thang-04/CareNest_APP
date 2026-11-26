import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';

/// Sức khỏe đầu ngày từ BE: danh sách bé có mặt = `GET /classes/{classId}/attendance[?date=]` (`record` PRESENT +
/// `health` HealthSummary); lịch sử trong ngày = `GET /classes/{classId}/children/{childId}/daily-health[?date=]`;
/// ghi = `POST /daily-health-entries` (requestId do màn sinh, gửi lặp trả bản đã lưu).
/// Sổ lớp chưa trả `handedOverAt` ⇒ để trống ở danh sách; ghi cho bé đã trả BE từ chối (HEALTH_CHILD_PICKED_UP).
class LiveDailyHealthSource implements DailyHealthSource {
  LiveDailyHealthSource(this._api);

  final MobileApi _api;

  static String _query(DateTime? date) =>
      date == null ? '' : '?date=${apiDate(date)}';

  @override
  Future<DailyHealthSheet> loadSheet(String classId, {DateTime? date}) async {
    final data =
        await _api.json('GET', '/classes/$classId/attendance${_query(date)}')
            as Map? ??
        const {};
    final day = data['day'] as Map? ?? const {};
    final sheetDate = DateTime.parse('${day['date']}');
    final rows = (data['children'] as List? ?? const []).whereType<Map>();
    return DailyHealthSheet(
      classId: classId,
      className: data['className']?.toString() ?? '',
      date: sheetDate,
      // Chỉ ghi được trong ngày hôm nay (BE kiểm tra lại)
      canRecord: data['canRecord'] == true && day['today'] == day['date'],
      schoolDay: day['schoolDay'] != false,
      kids: [
        for (final row in rows)
          if ((row['record'] as Map?)?['status'] == 'PRESENT')
            _kid(row, classId, sheetDate),
      ],
    );
  }

  @override
  Future<DailyHealthChildDay> loadChildDay(
    String classId,
    String childId, {
    DateTime? date,
  }) async {
    final data =
        await _api.json(
              'GET',
              '/classes/$classId/children/$childId/daily-health${_query(date)}',
            )
            as Map? ??
        const {};
    return DailyHealthChildDay(
      canRecord: data['canRecord'] == true,
      handedOverAt: switch (data['handedOverAt']) {
        final String at => DateTime.parse(at).toLocal(),
        _ => null,
      },
      entries: [
        for (final item
            in (data['entries'] as List? ?? const []).whereType<Map>())
          _entry(
            item,
            classId,
            childId,
            DateTime.tryParse('${item['date']}') ?? date ?? DateTime.now(),
          ),
      ],
    );
  }

  @override
  Future<DailyHealthEntry> save(DailyHealthEntry entry) async {
    final referral = entry.referral;
    final data =
        await _api.json(
              'POST',
              '/daily-health-entries',
              body: {
                'requestId': entry.requestId,
                'classId': int.tryParse(entry.classId) ?? entry.classId,
                'childId': int.tryParse(entry.childId) ?? entry.childId,
                'date': apiDate(entry.date),
                // BE chỉ nhận tối đa 1 số thập phân (20,0–45,0)
                'temperature': entry.temperature == null
                    ? null
                    : (entry.temperature! * 10).round() / 10,
                'observation': entry.observation.code,
                'symptoms': [for (final s in entry.symptoms) s.code],
                'actions': [for (final a in entry.actions) a.code],
                if (entry.note != null) 'note': entry.note,
                if (referral != null)
                  'referral': {
                    'place': referral.place,
                    'time': referral.time,
                    'escort': referral.escort,
                  },
              },
            )
            as Map? ??
        const {};
    return _entry(data, entry.classId, entry.childId, entry.date);
  }

  static DailyHealthKid _kid(
    Map<Object?, Object?> row,
    String classId,
    DateTime date,
  ) {
    final child = row['child'] as Map? ?? const {};
    final health = row['health'] as Map? ?? const {};
    final childId = '${child['id']}';
    return DailyHealthKid(
      childId: childId,
      fullName: child['fullName']?.toString() ?? '',
      code: child['code']?.toString(),
      entryCount: (health['entryCount'] as num?)?.toInt() ?? 0,
      // Tóm tắt không có requestId, hành động, chuyển viện
      latest: health['checked'] == true
          ? _entry(health, classId, childId, date)
          : null,
    );
  }

  static DailyHealthEntry _entry(
    Map<Object?, Object?> data,
    String classId,
    String childId,
    DateTime date,
  ) {
    final referral = data['referral'] as Map?;
    return DailyHealthEntry(
      requestId: data['requestId']?.toString() ?? '',
      classId: classId,
      childId: childId,
      date: date,
      observation:
          HealthObservation.values
              .where((o) => o.code == data['observation'])
              .firstOrNull ??
          HealthObservation.noConcern,
      temperature: (data['temperature'] as num?)?.toDouble(),
      symptoms: [
        for (final code in data['symptoms'] as List? ?? const [])
          ...HealthSymptom.values.where((s) => s.code == code),
      ],
      actions: [
        for (final code in data['actions'] as List? ?? const [])
          ...HealthAction.values.where((a) => a.code == code),
      ],
      note: data['note']?.toString(),
      referral: referral == null
          ? null
          : HealthReferral(
              place: referral['place']?.toString(),
              time: referral['time']?.toString(),
              escort: referral['escort']?.toString(),
            ),
      recordedAt: switch (data['recordedAt']) {
        final String at => DateTime.parse(at).toLocal(),
        _ => null,
      },
      recordedByName: data['recordedByName']?.toString(),
    );
  }
}

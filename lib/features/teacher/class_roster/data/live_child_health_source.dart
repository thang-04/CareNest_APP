import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/child_health.dart';
import 'package:carenest_app/features/teacher/class_roster/domain/health_labels.dart';

/// Sổ sức khỏe từ BE: `GET /children/{id}/health` (`ChildHealthRecordResponse.measurements`, mới nhất
/// trước). Không gọi `trend-analysis` vì đó là bản nháp AI; chỉ hiện số đo và cảnh báo BE đã xếp.
class LiveChildHealthSource implements ChildHealthSource {
  LiveChildHealthSource(this._api);

  final MobileApi _api;

  @override
  Future<ChildHealthHistory> load(String childId) async {
    final record =
        await _api.json('GET', '/children/$childId/health') as Map? ?? const {};
    final entries = <HealthEntry>[];
    for (final m
        in (record['measurements'] as List? ?? const []).whereType<Map>()) {
      final date = DateTime.tryParse('${m['date']}');
      if (date == null || m['published'] == false) continue;
      final exam = m['source'] == 'EXAM';
      final warning = exam
          ? followUpLabel(m['followUpLevel'])
          : bmiStatusLabel(m['bmiStatus']);
      entries.add(
        HealthEntry(
          date: date,
          title: m['campaignName']?.toString() ?? '',
          kindLabel: campaignKindLabel(m['campaignKind']),
          heightCm: (m['heightCm'] as num?)?.toDouble(),
          weightKg: (m['weightKg'] as num?)?.toDouble(),
          bmi: (m['bmi'] as num?)?.toDouble(),
          ageMonths: (m['ageMonths'] as num?)?.toInt(),
          warningLabel: warning?.label,
          warningTone: warning?.tone,
        ),
      );
    }
    return ChildHealthHistory(childId: childId, entries: entries);
  }
}

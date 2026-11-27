import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/teacher/activity_schedule/domain/activity_schedule.dart';

/// Hoạt động dạy học lấy từ kế hoạch ngày đã ban hành; ứng dụng chỉ xem.
class LiveActivityScheduleSource implements ActivityScheduleSource {
  LiveActivityScheduleSource(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final DateTime Function() _clock;

  @override
  Future<WeekSchedule> loadWeek(String classId) async {
    final now = _clock();
    final monday = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday),
    );
    final data =
        await _api.json(
              'GET',
              '/classes/$classId/teaching-activities?weekStart=${apiDate(monday)}',
            )
            as List? ??
        const [];
    final days = <int, List<ScheduleEntry>>{};
    var weekLabel = '';
    for (final raw in data.whereType<Map>()) {
      final date = DateTime.tryParse('${raw['date']}');
      if (date == null) continue;
      weekLabel = raw['weekLabel']?.toString() ?? weekLabel;
      final entries = <ScheduleEntry>[];
      for (final activity
          in (raw['activities'] as List? ?? const []).whereType<Map>()) {
        final title = activity['label']?.toString().trim() ?? '';
        final topic = activity['topic']?.toString().trim() ?? '';
        if (title.isEmpty && topic.isEmpty) continue;
        entries.add(
          ScheduleEntry(
            time: '',
            title: title.isEmpty ? topic : title,
            detail: topic.isEmpty || topic == title ? null : topic,
          ),
        );
      }
      days[date.weekday] = entries;
    }
    return WeekSchedule(
      weekStart: monday,
      theme: weekLabel.isEmpty ? 'Hoạt động tuần' : weekLabel,
      days: days,
    );
  }
}

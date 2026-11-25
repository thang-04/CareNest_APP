import 'package:carenest_app/core/integration/api_dates.dart';
import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/core/utils/date_labels.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';
import 'package:carenest_app/features/teacher/daily_health/domain/daily_health.dart';
import 'package:carenest_app/features/teacher/pickup/domain/pickup.dart';

/// "Bé của tôi" từ BE: hồ sơ = `GET /children/{id}/profile`; điểm danh tháng =
/// `GET /children/{id}/attendance` + sức khỏe đầu ngày `GET /children/{id}/daily-health/parent` (ATT-15).
class LiveMyChildSource implements MyChildSource {
  LiveMyChildSource(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MobileApi _api;
  final DateTime Function() _clock;

  /// Q1 (user 25/11): BE chưa có API hoạt động trong ngày; phiên thật mở "Sắp có", không gọi tới đây.
  @override
  Future<ActivityDay> loadActivities(String childId) =>
      Future.error(UnsupportedError('Hoạt động trong ngày chưa có API'));

  @override
  Future<AttendanceMonth> loadAttendance(String childId) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final month = DateTime(now.year, now.month);
    final monday = mondayOf(today);
    // Tới hôm nay, không tới cuối tháng: BE từ chối khoảng vượt cuối năm học (4109).
    // Tháng khai giảng: ngày 1 có thể trước năm học ⇒ thu hẹp về tuần này, rồi hôm nay.
    final results = await loadFromNearestStart(
      [
        month,
        if (monday.isAfter(month)) monday,
        if (today.isAfter(monday) && today.isAfter(month)) today,
      ],
      (from) {
        final query = 'from=${apiDate(from)}&to=${apiDate(today)}';
        return Future.wait([
          _api.json('GET', '/children/$childId/attendance?$query'),
          _api.json('GET', '/children/$childId/daily-health/parent?$query'),
        ]);
      },
      // Ngoài năm học (hè): tháng không có ngày học
      outsideYear: () => const [<String, Object?>{}, <Object>[]],
    );
    final data = results[0]! as Map;
    final totals = data['totals'] as Map? ?? const {};
    // BE xếp mới nhất trước ⇒ giữ lần ghi đầu tiên của mỗi ngày
    final health = <String, Map>{};
    for (final entry in (results[1] as List? ?? const []).whereType<Map>()) {
      health.putIfAbsent('${entry['date']}', () => entry);
    }
    return AttendanceMonth(
      month: month,
      presentCount: _count(totals['present']),
      excusedCount: _count(totals['excused']),
      absentCount: _count(totals['absent']),
      days: [
        for (final day in (data['days'] as List? ?? const []).whereType<Map>())
          if (_dayStatus(day['status']) case final status?)
            _day(day, status, health['${day['date']}']),
      ],
    );
  }

  @override
  Future<ChildProfile> loadProfile(String childId) async {
    final data = await _api.json('GET', '/children/$childId/profile') as Map;
    final child = data['child'] as Map? ?? const {};
    final cls = data['cls'] as Map?;
    final declaration = data['declaration'] as Map?;
    final history = declaration?['medicalHistory'] as Map?;
    final allergies = declaration?['allergies'] as Map?;
    return ChildProfile(
      fullName: child['fullName']?.toString() ?? '',
      className: (child['className'] ?? cls?['name'])?.toString() ?? '',
      birthDate: switch (child['dateOfBirth']) {
        final String date => DateLabels.date(DateTime.parse(date)),
        _ => '',
      },
      gender: switch (child['gender']) {
        'MALE' => 'Nam',
        'FEMALE' => 'Nữ',
        _ => '',
      },
      health: DeclaredHealth(
        allergyState: _state(allergies?['state']),
        allergies: [
          for (final item in allergies?['items'] as List? ?? const []) '$item',
        ],
        diet: _item(declaration?['diet']),
        selfHistory: _item(history?['self']),
        familyHistory: _item(history?['family']),
      ),
      // Chỉ quan hệ, tên, SĐT; số CCCD trong hồ sơ không hiện cho phụ huynh
      guardians: [
        for (final g
            in (child['guardians'] as List? ?? const []).whereType<Map>())
          Guardian(
            relation:
                _label(
                  GuardianRelationship.values,
                  g['relation'],
                  (r) => r.code,
                  (r) => r.label,
                ) ??
                GuardianRelationship.other.label,
            name: g['fullName']?.toString() ?? '',
            phone: g['phone']?.toString(),
          ),
      ],
    );
  }

  static double _count(Object? value) => (value as num?)?.toDouble() ?? 0;

  /// Không phải ngày học / chưa vào lớp / chưa điểm danh ⇒ không có dấu trên lịch.
  static AttendanceDayStatus? _dayStatus(Object? code) => switch (code) {
    'PRESENT' => AttendanceDayStatus.present,
    'ABSENT_EXCUSED' => AttendanceDayStatus.excused,
    'ABSENT' => AttendanceDayStatus.absent,
    _ => null,
  };

  static AttendanceDay _day(
    Map<Object?, Object?> day,
    AttendanceDayStatus status,
    Map<Object?, Object?>? health,
  ) {
    final eaten = _meals(day['mealsEaten']);
    return AttendanceDay(
      date: DateTime.parse(day['date']! as String),
      status: status,
      arrivedAt: switch (day['arrivedAt']) {
        final String at => DateTime.parse(at).toLocal(),
        _ => null,
      },
      mealsLine: eaten.isEmpty ? null : 'đã ăn ${eaten.join(' · ')}',
      mealCancelled: (day['cancelledMeals'] as List? ?? const []).isNotEmpty,
      absentPart: switch (day['absentPart']) {
        'MORNING' => AbsentPart.morning,
        'AFTERNOON' => AbsentPart.afternoon,
        _ => null,
      },
      healthLine: health == null ? null : _healthLine(health),
      healthNote: health?['note']?.toString(),
    );
  }

  static List<String> _meals(Object? codes) => [
    for (final code in codes as List? ?? const [])
      ?switch (code) {
        'MORNING' => 'sáng',
        'LUNCH' => 'trưa',
        'AFTERNOON' => 'chiều',
        _ => null,
      },
  ];

  static String _healthLine(Map<Object?, Object?> health) {
    final symptoms = [
      for (final code in health['symptoms'] as List? ?? const [])
        ?_label(HealthSymptom.values, code, (s) => s.code, (s) => s.label),
    ];
    return [
      if (health['temperature'] case final num t)
        '${t.toStringAsFixed(1).replaceAll('.', ',')} °C',
      if (symptoms.isNotEmpty) symptoms.join(', '),
    ].join(' · ');
  }

  static DeclarationState _state(Object? code) => switch (code) {
    'REPORTED' => DeclarationState.reported,
    'NONE_REPORTED' => DeclarationState.noneReported,
    _ => DeclarationState.notProvided,
  };

  static DeclaredItem _item(Object? answer) {
    final map = answer as Map?;
    return switch (_state(map?['state'])) {
      DeclarationState.reported => DeclaredItem.reported(
        map?['text']?.toString() ?? '',
      ),
      DeclarationState.noneReported => const DeclaredItem.noneReported(),
      DeclarationState.notProvided => const DeclaredItem.notProvided(),
    };
  }

  /// Nhãn tiếng Việt của mã enum BE (dùng chung bảng nhãn với màn GV).
  static String? _label<T>(
    List<T> values,
    Object? code,
    String Function(T) codeOf,
    String Function(T) labelOf,
  ) {
    for (final value in values) {
      if (codeOf(value) == code) return labelOf(value);
    }
    return null;
  }
}

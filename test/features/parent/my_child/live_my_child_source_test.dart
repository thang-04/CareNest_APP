import 'package:flutter_test/flutter_test.dart';

import 'package:carenest_app/core/integration/mobile_api.dart';
import 'package:carenest_app/features/parent/my_child/data/live_my_child_source.dart';
import 'package:carenest_app/features/parent/my_child/domain/my_child.dart';
import 'package:carenest_app/features/parent/parent_home/domain/parent_today.dart';

import '../../../helpers/live_fakes.dart';

void main() {
  late FakeLiveSession session;
  final today = DateTime(2026, 11, 25);
  const range = 'from=2026-11-01&to=2026-11-25';

  setUp(() => session = FakeLiveSession(['PARENT'], childIds: [5]));

  LiveMyChildSource source(Map<String, Object? Function(Object?)> routes) =>
      LiveMyChildSource(ScriptedApi(session, routes), clock: () => today);

  test('loadProfile_mapsDeclarationAndGuardians', () async {
    final profile = profileJson(5, 'Nguyễn Minh Anh');
    final child = profile['child']! as Map<String, Object?>;
    child['gender'] = 'MALE';
    child['guardians'] = [
      {
        'fullName': 'Trần Thu Lan',
        'relation': 'MOTHER',
        'phone': '0900000001',
        'idNumber': '000000000001',
      },
      {'fullName': 'Nguyễn Văn Hùng', 'relation': 'FATHER', 'phone': null},
    ];
    profile['declaration'] = {
      'allergies': {
        'state': 'REPORTED',
        'items': ['Hải sản'],
      },
      'diet': {'state': 'NONE_REPORTED', 'text': null},
      'medicalHistory': {
        'self': {'state': 'REPORTED', 'text': 'Hen phế quản'},
        'family': {'state': 'NOT_PROVIDED', 'text': null},
      },
    };

    final result = await source({
      'GET /children/5/profile': (_) => profile,
    }).loadProfile('5');

    expect(result.fullName, 'Nguyễn Minh Anh');
    expect(result.className, 'Mầm 3A');
    expect(result.birthDate, '14/03/2022');
    expect(result.gender, 'Nam');
    // BE chưa trả tên năm học, điểm trường, GV, tuổi ⇒ ẩn (user 25/11)
    expect(result.schoolYear, isNull);
    expect(result.campus, isNull);
    expect(result.teachers, isNull);
    expect(result.ageLabel, isNull);
    expect(result.health.allergyState, DeclarationState.reported);
    expect(result.health.allergies, ['Hải sản']);
    expect(result.health.diet.state, DeclarationState.noneReported);
    expect(result.health.selfHistory.text, 'Hen phế quản');
    expect(result.health.familyHistory.state, DeclarationState.notProvided);
    expect(result.guardians.map((g) => '${g.relation}|${g.name}|${g.phone}'), [
      'Mẹ|Trần Thu Lan|0900000001',
      'Bố|Nguyễn Văn Hùng|null',
    ]);
  });

  test('loadProfile_noDeclaration_allNotProvided', () async {
    final result = await source({
      'GET /children/5/profile': (_) => profileJson(5, 'Nguyễn Minh Anh'),
    }).loadProfile('5');

    expect(result.health.allergyState, DeclarationState.notProvided);
    expect(result.health.diet.state, DeclarationState.notProvided);
    expect(result.health.selfHistory.state, DeclarationState.notProvided);
    expect(result.health.familyHistory.state, DeclarationState.notProvided);
  });

  Map<String, Object? Function(Object?)> attendanceRoutes({
    List<Object> days = const [],
    Map<String, Object?> totals = const {
      'schoolDays': 0,
      'present': 0,
      'excused': 0,
      'absent': 0,
    },
    List<Object> health = const [],
  }) => {
    'GET /children/5/attendance?$range': (_) => {
      'childId': 5,
      'from': '2026-11-01',
      'to': '2026-11-25',
      'days': days,
      'totals': totals,
    },
    'GET /children/5/daily-health/parent?$range': (_) => health,
  };

  test('loadAttendance_requestsCalendarMonth', () async {
    final routes = attendanceRoutes();
    final api = ScriptedApi(session, routes);
    final month = await LiveMyChildSource(
      api,
      clock: () => today,
    ).loadAttendance('5');

    // Từ ngày 1 tới hôm nay: BE từ chối khoảng vượt cuối năm học (4109)
    expect(api.calls, unorderedEquals(routes.keys));
    expect(month.month, DateTime(2026, 11));
  });

  test('loadAttendance_rangeBeforeYearStart_retriesFromThisWeek', () async {
    // Tháng đầu năm học: ngày 1 trước ngày khai giảng ⇒ BE 4109; thử lại từ thứ Hai tuần này
    final routes = attendanceRoutes();
    Never reject(Object? _) =>
        throw ApiFailure(400, 'Chọn khoảng ngày trong một năm học', 4109);
    routes['GET /children/5/attendance?$range'] = reject;
    routes['GET /children/5/daily-health/parent?$range'] = reject;
    const week = 'from=2026-11-23&to=2026-11-25';
    routes['GET /children/5/attendance?$week'] = (_) => {
      'days': <Object>[],
      'totals': {'present': 2},
    };
    routes['GET /children/5/daily-health/parent?$week'] = (_) => <Object>[];

    final month = await source(routes).loadAttendance('5');

    expect(month.presentCount, 2);
  });

  test('loadAttendance_outsideSchoolYear_emptyMonth', () async {
    Never reject(Object? _) =>
        throw ApiFailure(400, 'Chọn khoảng ngày trong một năm học', 4109);
    final month = await source({
      for (final from in ['11-01', '11-23', '11-25']) ...{
        'GET /children/5/attendance?from=2026-$from&to=2026-11-25': reject,
        'GET /children/5/daily-health/parent?from=2026-$from&to=2026-11-25':
            reject,
      },
    }).loadAttendance('5');

    expect(month.days, isEmpty);
    expect(month.presentCount, 0);
  });

  test('loadAttendance_otherError_notRetried', () async {
    final routes = attendanceRoutes();
    routes['GET /children/5/attendance?$range'] = (_) =>
        throw ApiFailure(403, 'Bạn chỉ xem được thông tin của con mình', 4108);

    await expectLater(
      source(routes).loadAttendance('5'),
      throwsA(isA<ApiFailure>().having((f) => f.status, 'status', 403)),
    );
  });

  test('loadAttendance_countsHalfDays', () async {
    final month = await source(
      attendanceRoutes(
        days: [
          {
            'date': '2026-11-23',
            'status': 'NO_SCHOOL',
            'mealsEaten': <String>[],
            'cancelledMeals': <String>[],
          },
          {
            'date': '2026-11-24',
            'status': 'PRESENT',
            'absentPart': 'MORNING',
            'arrivedAt': '2026-11-24T06:05:00Z',
            'mealsEaten': ['LUNCH', 'AFTERNOON'],
            'cancelledMeals': ['MORNING'],
          },
          {
            'date': '2026-11-25',
            'status': 'NOT_RECORDED',
            'mealsEaten': <String>[],
            'cancelledMeals': <String>[],
          },
        ],
        totals: {'schoolDays': 9, 'present': 8.5, 'excused': 0.5, 'absent': 0},
      ),
    ).loadAttendance('5');

    expect(month.presentCount, 8.5);
    expect(month.excusedCount, 0.5);
    expect(month.absentCount, 0);
    // BE chưa trả tổng suất huỷ ⇒ không tự đếm trên máy
    expect(month.cancelledMealCount, isNull);
    // Ngày không phải ngày học / chưa điểm danh không có dấu trên lịch
    expect(month.days, hasLength(1));
    final day = month.days.single;
    expect(day.date, DateTime(2026, 11, 24));
    expect(day.status, AttendanceDayStatus.present);
    expect(day.absentPart, AbsentPart.morning);
    expect(day.arrivedAt, DateTime.utc(2026, 11, 24, 6, 5).toLocal());
    expect(day.mealsLine, 'đã ăn trưa · chiều');
    expect(day.mealCancelled, isTrue);
    expect(day.pickupLine, isNull);
  });

  test('loadAttendance_attachesDailyHealth', () async {
    final month = await source(
      attendanceRoutes(
        days: [
          {
            'date': '2026-11-24',
            'status': 'PRESENT',
            'mealsEaten': <String>[],
            'cancelledMeals': <String>[],
          },
        ],
        health: [
          {
            'date': '2026-11-24',
            'temperature': 37.8,
            'symptoms': ['FEVER', 'COUGH'],
            'note': 'Cô đã báo mẹ',
          },
          {
            'date': '2026-11-24',
            'temperature': 36.6,
            'symptoms': <String>[],
            'note': null,
          },
        ],
      ),
    ).loadAttendance('5');

    final day = month.days.single;
    // BE xếp mới nhất trước ⇒ lấy lần ghi đầu tiên của ngày
    expect(day.healthLine, '37,8 °C · Sốt, Ho');
    expect(day.healthNote, 'Cô đã báo mẹ');
  });

  test('loadAttendance_notRecordedWithHealth_kept_emptyHealthHidden', () async {
    final month = await source(
      attendanceRoutes(
        days: [
          {'date': '2026-11-25', 'status': 'NOT_RECORDED'},
          {'date': '2026-11-24', 'status': 'NOT_RECORDED'},
          {'date': '2026-11-23', 'status': 'PRESENT', 'pickedUpByName': 'Mẹ'},
        ],
        health: [
          {
            'date': '2026-11-25',
            'temperature': 36.5,
            'symptoms': <String>[],
            'note': 'Bé khỏe',
          },
          {
            'date': '2026-11-23',
            'temperature': null,
            'symptoms': <String>[],
            'note': '  ',
          },
        ],
      ),
    ).loadAttendance('5');

    // Chưa điểm danh nhưng đã có sức khỏe đầu ngày ⇒ vẫn hiện; chưa có gì ⇒ bỏ
    expect(month.days.map((d) => d.date.day), [25, 23]);
    expect(month.days.first.status, AttendanceDayStatus.notRecorded);
    expect(month.days.first.healthLine, '36,5 °C');
    expect(month.days.last.healthLine, isNull);
    expect(month.days.last.healthNote, isNull);
    expect(month.days.last.pickupLine, 'Mẹ');
  });
}
